#!/usr/bin/env bash
#
# setup.sh - Recreate the MyTemplate dev environment from scratch on a fresh
# Ubuntu machine (EC2 or otherwise).
#
# Everything that was previously done manually and ad-hoc (the Ignite->
# MyTemplate rename, pyproject.toml, Makefile targets, Dockerfile) is now
# committed to the repo itself, so this script only needs to install
# dependencies and verify the pipeline - it does NOT redo any of that
# one-time repo surgery.
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh                 # full setup + interactive test menu
#   ./setup.sh --list-tests    # just list available test cases and exit
#   ./setup.sh --no-menu       # full setup, skip the interactive menu (CI use)
#
# Idempotent: safe to re-run. Exits immediately on any real error.

set -euo pipefail

REPO_URL="https://github.com/it-is-that-is/mytemplate.git"
REPO_DIR="mytemplate"

# --- Optional early exit: just list test cases, no setup ------------------
if [ "${1:-}" = "--list-tests" ]; then
    if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; fi
    if [ -d "env" ]; then
        source env/bin/activate
    fi
    echo "=== Available test cases ==="
    python -m pytest --collect-only -q 2>/dev/null || echo "Run full setup first - pytest not available yet."
    exit 0
fi

NO_MENU=false
if [ "${1:-}" = "--no-menu" ]; then
    NO_MENU=true
fi

echo "=== 1. System packages ==="
sudo apt update
sudo apt install -y python3-venv python3-pip nginx git make curl docker.io

echo "=== 2. Docker permissions (skip if already configured) ==="
if ! groups "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
    echo "Added $USER to docker group. You must log out and back in (or run"
    echo "'newgrp docker') before Docker commands work without sudo."
fi
sudo systemctl enable docker
sudo systemctl start docker

echo "=== 3. Clone repo (skip if already present) ==="
if [ ! -d "$REPO_DIR" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"

echo "=== 4. Python virtual environment ==="
if [ ! -d "env" ]; then
    python3 -m venv env
fi
source env/bin/activate

echo "=== 5. Install Python dependencies ==="
python -m pip install --upgrade pip
python -m pip install -r requirements.txt -r requirements-dev.txt

echo "=== 6. Install Playwright browser ==="
python -m playwright install --with-deps chromium

echo "=== 7. Seed the database ==="
python manage.py resetdb

echo "=== 8. Confirm the app boots (quick smoke check, then stop it) ==="
timeout 5 python -m flask --debug run --host=0.0.0.0 > /tmp/flask_boot_check.log 2>&1 &
FLASK_PID=$!
sleep 3
if curl -sf http://127.0.0.1:5000/ > /dev/null; then
    echo "App boots successfully."
else
    echo "WARNING: app did not respond on port 5000. Check /tmp/flask_boot_check.log"
fi
kill "$FLASK_PID" 2>/dev/null || true

echo ""
echo "=== Setup complete ==="
echo "Seeded login: user@example.com / test"

if [ "$NO_MENU" = true ]; then
    echo "=== Running full pipeline (--no-menu) ==="
    make report
    exit 0
fi

while true; do
    echo ""
    echo "=== What do you want to run? ==="
    echo "  1) List all available test cases (no run)"
    echo "  2) Run full backend test suite (pytest)"
    echo "  3) Run a single test file"
    echo "  4) Run full QA pipeline: tests + lint + security (make report)"
    echo "  5) Run UI test only (requires 'make run' in another terminal first)"
    echo "  6) Run full pipeline including UI test (make ci)"
    echo "  7) Build Docker image"
    echo "  0) Exit"
    read -rp "Choice: " choice

    case "$choice" in
        1)
            echo "--- Test cases ---"
            python -m pytest --collect-only -q
            ;;
        2)
            python -m pytest tests/ --ignore=tests/test_ui_login.py -v
            ;;
        3)
            echo "Available test files:"
            find tests -name "test_*.py" -printf "  %f\n"
            read -rp "Enter test filename (e.g. test_smoke.py): " tfile
            if [ -f "tests/$tfile" ]; then
                python -m pytest "tests/$tfile" -v
            else
                echo "File not found: tests/$tfile"
            fi
            ;;
        4)
            make report
            ;;
        5)
            echo "Make sure 'make run' is active in another terminal first."
            read -rp "Press Enter once the app is running on :5000..." _
            make test-ui
            ;;
        6)
            echo "Make sure 'make run' is active in another terminal first."
            read -rp "Press Enter once the app is running on :5000..." _
            make ci
            ;;
        7)
            docker build -t mytemplate:latest .
            ;;
        0)
            echo "Done."
            break
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
done
