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

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :headless_edge

  # The auth screens and the app proper both sign in through the real form —
  # a system test exists to walk the app the way a student does, so no cookie
  # shortcuts here.
  def sign_in_through_the_form(user, password: "password")
    visit "/login"
    fill_in "student_id", with: user.student_id
    fill_in "password", with: password
    # By selector, not label: the sign-in tab above the form carries the same
    # "เข้าสู่ระบบ" as the submit.
    find("input[type=submit]").click
  end
end
