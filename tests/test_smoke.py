def test_homepage_loads(testapp):
    """The homepage should load successfully for an anonymous visitor."""
    response = testapp.get("/")
    assert response.status_code == 200


def test_login_page_shows_mytemplate_branding(testapp):
    """The login page title should reflect the MyTemplate rebrand.

    Note: the page body legitimately contains "Ignite" in one place - a pinned
    CDN URL (rawcdn.githack.com/Sumukh/Ignite/...) referencing the original
    template's CSS asset by commit hash. That's an external resource reference,
    not app branding, so this test checks the <title> tag specifically rather
    than asserting "Ignite" is absent from the whole page.
    """
    response = testapp.get("/login")
    assert response.status_code == 200
    assert b"<title>MyTemplate" in response.data


def test_user_can_log_in(testapp):
    """A seeded user should be able to log in and reach an authenticated page."""
    response = testapp.post(
        "/login",
        data={"email": "user@example.com", "password": "safepassword"},
        follow_redirects=True,
    )
    assert response.status_code == 200

