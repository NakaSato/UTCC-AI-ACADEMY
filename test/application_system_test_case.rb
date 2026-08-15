require "test_helper"

# Driven by Edge because that is the browser this machine actually has — there
# is no Chrome here, and bin/ci runs locally by design. Selenium's manager
# fetches msedgedriver on first run, so nothing needs installing. To run these
# against another browser, swap the two :edge references below.
#
# Registered by hand rather than `driven_by :selenium, using:` because Rails'
# browser shorthand knows Chrome and Firefox, not a headless Edge.
Capybara.register_driver :headless_edge do |app|
  options = Selenium::WebDriver::Options.edge
  options.add_argument("--headless=new")
  options.add_argument("--window-size=1400,1000")
  options.add_argument("--hide-scrollbars")
  # The tests assert the app's default Thai copy, so the browser must ask for
  # Thai — a headless profile otherwise sends Accept-Language: en, and anything
  # that negotiates the locale would answer in English.
  options.add_argument("--lang=th")
  options.add_preference("intl.accept_languages", "th")

  Capybara::Selenium::Driver.new(app, browser: :edge, options: options)
end

# Parallel browser runs can make an otherwise successful Turbo response take
# longer than Capybara's two-second default. Keep every assertion event-driven,
# but give it the same ten-second ceiling already used by the sign-in boundary.
Capybara.default_max_wait_time = 10

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :headless_edge

  # Capybara 3.40 asks Edge to clear cookies through CDP only after navigating
  # to about:blank. Edge accepts that request but can leave the encrypted Rails
  # session cookie behind, allowing a selected locale (or an authenticated
  # session) to cross into the next test. Clear cookies while the app origin is
  # still active; Rails' normal teardown then resets the rest of the browser.
  def after_teardown
    page.driver.browser.manage.delete_all_cookies
  ensure
    super
  end

  # Reaching a destination costs two clicks now: the header is a menubar of
  # categories, each opening its own dropdown, so a test that walks the app the
  # way a person does has to open the right category first. Which one holds a
  # destination is `app_nav_groups`' business, not a caller's, so this looks.
  def navigate_to(label)
    all("nav[aria-label] button[data-nav-group]").each do |category|
      category.click
      panel = category.find(:xpath, "following-sibling::div[@data-menu='nav']")
      next unless panel.has_link?(label, wait: 0.5)

      return panel.click_link(label)
    end

    raise Capybara::ElementNotFound, "no navigation category offers #{label.inspect}"
  end

  # The auth screens and the app proper both sign in through the real form —
  # a system test exists to walk the app the way a student does, so no cookie
  # shortcuts here.
  def sign_in_through_the_form(user, password: "password")
    # Teardown cleanup is best effort in Edge. Establish the app origin and
    # clear again before an explicit sign-in so a prior test's return path or
    # authenticated session cannot decide this test's destination. The second
    # visit and everything after it still exercise the real form and session.
    visit "/login"
    page.driver.browser.manage.delete_all_cookies
    visit "/login"
    fill_in "student_id", with: user.student_id
    fill_in "password", with: password
    # By selector, not label: the sign-in tab above the form carries the same
    # "เข้าสู่ระบบ" as the submit.
    find("input[type=submit]").click

    # `/` is each workspace's own front door now, so where sign-in lands depends
    # on who signed in — a company member goes to the work waiting on their
    # company, not to a catalogue of courses they are not taking. See SPEC-0044
    # and SPEC-0048.
    #
    # Turbo changes the URL before Edge always exposes the replacement document.
    # Waiting on the destination keeps callers from querying an outgoing, stale
    # document, whichever destination it is.
    assert_current_path workspace_home(user), wait: 10
    assert_selector "h1", text: I18n.t("catalog.title"), wait: 10 if user.workspace == :student
  end

  private
    def workspace_home(user)
      case user.workspace
      in :admin then admin_path
      in :instructor then instructor_path
      in :company then company_home_path(user)
      else root_path
      end
    end

    # Mirrors HomeController#company_home: one organization means the company's
    # own page, more than one means the list.
    # A company member lands on the work waiting for them, not on their
    # company's record — SPEC-0048. Two companies and there is a choice to
    # make first, so the list stays the destination.
    def company_home_path(user)
      organizations = user.organizations.merge(Organization.active)

      organizations.one? ? work_company_path(organizations.first) : companies_path
    end
end
