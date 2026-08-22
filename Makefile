.PHONY: docs test agent-setup agent-resetdb agent-smoke agent-test

VENV_PYTHON=env/bin/python
AGENT_TEST_FILES=$(shell git ls-files 'tests/*.py')

help:
	@echo "  env         create a development environment using virtualenv"
	@echo "  deps        install dependencies using pip"
	@echo "  clean       remove unwanted files like .pyc's"
	@echo "  lint        check style with flake8"
	@echo "  test        run all your tests using py.test"
	@echo "  agent-setup install dependencies in ./env for AI/code agents"
	@echo "  agent-resetdb reset and seed local development database"
	@echo "  agent-smoke run fast smoke tests"
	@echo "  agent-test  run full test suite with coverage"

env:
	python3 -m venv env && \
	. env/bin/activate && \
	make deps

deps:
	pip install -r requirements.txt

clean:
	find . | grep -E "(__pycache__|\.pyc|\.DS_Store|\.db|\.pyo$\)" | xargs rm -rf

lint-flake8:
	flake8 --exclude=env .

test:
	py.test tests

agent-setup:
	python3 -m venv env
	$(VENV_PYTHON) -m pip install --upgrade pip
	$(VENV_PYTHON) -m pip install -r requirements.txt

agent-resetdb:
	@if [ ! -x "$(VENV_PYTHON)" ]; then echo "Run 'make agent-setup' first."; exit 1; fi
	APPNAME_ENV=dev $(VENV_PYTHON) manage.py resetdb

agent-smoke:
	@if [ ! -x "$(VENV_PYTHON)" ]; then echo "Run 'make agent-setup' first."; exit 1; fi
	APPNAME_ENV=test $(VENV_PYTHON) -m pytest -q tests/test_urls.py tests/test_login.py

agent-test:
	@if [ ! -x "$(VENV_PYTHON)" ]; then echo "Run 'make agent-setup' first."; exit 1; fi
	APPNAME_ENV=test $(VENV_PYTHON) -m pytest --cov-report=term-missing --cov=appname $(AGENT_TEST_FILES)

# --- New: DevOps/QA assessment pipeline targets ----------------------------

setup: agent-setup
	env/bin/pip install -r requirements-dev.txt
	env/bin/python -m playwright install --with-deps chromium

resetdb:
	python manage.py resetdb

run:
	python -m flask --debug run

# Backend tests with coverage + JUnit XML. Excludes the UI test (needs a
# live server - see test-ui below) and deselects a pre-existing test that
# requires a local Redis server.
test-backend:
	mkdir -p reports
	python -m pytest tests/ --ignore=tests/test_ui_login.py \
		--junitxml=reports/junit.xml \
		--cov=. --cov-report=xml:reports/coverage.xml --cov-report=html:reports/coverage_html

# UI tests (Playwright). Requires the app already running locally
# (run `make run` in a separate terminal first) at http://127.0.0.1:5000.
test-ui:
	mkdir -p reports
	python -m pytest tests/test_ui_login.py --junitxml=reports/junit-ui.xml -v

lint:
	mkdir -p reports
	-python -m ruff check . --output-format=json --output-file=reports/ruff-report.json
	-python -m ruff check .

security:
	mkdir -p reports
	-python -m bandit -r . -x "./env,./tests,./__pycache__" -f json -o reports/bandit-report.json
	-python -m bandit -r . -x "./env,./tests,./__pycache__"

# Everything that doesn't need a live server.
report: test-backend lint security
	@echo "Reports available in ./reports"

# Full pipeline including UI tests. Requires the app running separately
# first (make run, in another terminal).
ci: report test-ui
	@echo "CI pipeline complete. Reports available in ./reports"
