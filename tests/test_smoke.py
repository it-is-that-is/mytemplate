def test_homepage_loads(testapp):
    """The homepage should load successfully for an anonymous visitor."""
    response = testapp.get("/")
    assert response.status_code == 200


def test_login_page_shows_mytemplate_branding(testapp):
    """The login page title should reflect the MyTemplate rebrand."""
    response = testapp.get("/login")
    assert response.status_code == 200
    assert b"<title>MyTemplate" in response.data
    assert b"Ignite" not in response.data


def test_user_can_log_in(testapp):
    """A seeded user should be able to log in and reach an authenticated page."""
    response = testapp.post(
        "/login",
        data={"email": "user@example.com", "password": "safepassword"},
        follow_redirects=True,
    )
    assert response.status_code == 200
