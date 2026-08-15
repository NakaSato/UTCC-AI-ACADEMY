require "application_system_test_case"

# The palette lives in a class on <html>, and only a browser can say whether it
# is still there after a navigation. Turbo copies exactly two attributes off the
# incoming page's <html> — `lang` and `dir` — so the theme toggle has to submit
# outside Turbo while the language toggle beside it does not. Both halves are
# pinned here, because the day Turbo changes that set is the day the palette
# silently stops switching.
class ThemeWalkTest < ApplicationSystemTestCase
  test "choosing a palette repaints the page and survives navigation" do
    visit "/"
    assert_no_selector "html.dark"
    assert_no_selector "html.light"

    click_theme "dark"

    assert_selector "html.dark"
    assert_equal "rgb(15, 12, 11)", body_background

    # And it stays through an ordinary Turbo visit, which is the common case —
    # the class only has to be written once, by a real page load.
    visit "/privacy"
    assert_selector "html.dark"
  end

  test "an explicit light choice beats the browser's own preference" do
    visit "/"
    click_theme "light"

    assert_selector "html.light"
    assert_equal "rgb(247, 244, 241)", body_background
  end

  test "system returns the answer to the browser" do
    visit "/"
    click_theme "dark"
    assert_selector "html.dark"

    click_theme "system"

    assert_no_selector "html.dark"
    assert_no_selector "html.light"
  end

  test "a signed-in user changes theme from the profile menu" do
    sign_in_through_the_form users(:one)

    find("button[aria-label='#{I18n.t("chrome.user_toggle")}']").click
    within("[data-menu=account]") do
      find("[data-preference=theme] > button").click
      find("form[action='#{theme_path(:dark)}'] button").click
    end

    assert_selector "html.dark"
  end

  # The reason the theme toggle is the odd one out. If a future Turbo starts
  # copying `class`, this still passes and the `data-turbo: false` above becomes
  # removable; if it stops copying `lang`, this fails and the language toggle
  # needs the same treatment.
  test "Turbo carries the lang attribute across a visit, which is why only the theme opts out" do
    visit "/"
    assert_selector "html[lang=th]"

    find("[data-preference=language] > button").click
    find("form[action='#{language_path(:en)}'] button").click

    assert_selector "html[lang=en]"
  end

  private
    def click_theme(theme)
      find("[data-preference=theme] > button").click
      find("form[action='#{theme_path(theme)}'] button").click
    end

    def body_background
      evaluate_script("getComputedStyle(document.body).backgroundColor")
    end
end
