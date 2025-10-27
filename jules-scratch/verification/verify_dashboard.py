from playwright.sync_api import sync_playwright

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()
    page.goto("http://localhost:8001")

    # Wait for the page to be fully loaded
    page.wait_for_load_state('load', timeout=60000)
    page.wait_for_timeout(2000)

    # Enable accessibility by dispatching a click event
    page.get_by_label("Enable accessibility").dispatch_event('click')
    page.wait_for_timeout(1000) # Wait for the accessibility tree to build

    # Now, the labels should be available
    email_input = page.get_by_label("Email")
    password_input = page.get_by_label("Password")

    email_input.fill("test@example.com")
    password_input.fill("password")

    login_button = page.get_by_role("button", name="Login")
    login_button.click()

    page.wait_for_load_state('load')
    page.wait_for_timeout(5000) # 5 seconds delay for dashboard to load

    page.screenshot(path="screenshot.png")

    browser.close()

with sync_playwright() as playwright:
    run(playwright)
