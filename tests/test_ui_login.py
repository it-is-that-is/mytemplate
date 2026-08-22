"""
UI test for the login flow, using Playwright.

This test expects the app to already be running locally (see README /
`make run`) at http://127.0.0.1:5000 — it does not start the server itself.
This keeps the test simple and mirrors how a QA engineer would run it against
a real, already-deployed environment.
"""

BASE_URL = "http://127.0.0.1:5000"


def test_login_flow_reaches_dashboard(page):
    """A seeded user should be able to log in through the real UI and land
    on the dashboard, and the page should reflect MyTemplate branding."""
    page.goto(f"{BASE_URL}/login")

    page.fill("input[name='email']", "user@example.com")
    page.fill("input[name='password']", "test")
    page.click("button[type='submit']")

    # Wait for navigation away from the login page. The dashboard URL
    # includes a team slug (e.g. /dashboard/qMa9M), so we check the path
    # directly rather than using a glob pattern (Playwright globs don't
    # match across "/", so "/dashboard*" would not match "/dashboard/qMa9M").
    page.wait_for_load_state("networkidle")
    assert "/dashboard" in page.url

    assert "MyTemplate" in page.title()

