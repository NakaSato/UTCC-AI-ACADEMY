require "test_helper"

# The palette toggle is the language toggle's twin: a session-backed preference,
# written by a POST, read back on the next render. What is asserted here is the
# contract the stylesheet depends on — the class on <html> — because the CSS
# keys off it and nothing server-side notices if it stops being written.
class ThemesTest < ActionDispatch::IntegrationTest
  test "a signed-out visitor can choose a palette" do
    post theme_path("dark"), headers: { "Referer" => root_url }

    assert_redirected_to root_url
    follow_redirect!
    assert_select "html.dark"
  end

  test "an explicit light choice is a class of its own" do
    # Not the absence of one: it has to beat a dark system setting, which is
    # what `:root:not(.light)` in the stylesheet is for.
    post theme_path("light")
    get root_path

    assert_select "html.light"
  end

  test "system clears the preference so the media query answers" do
    post theme_path("dark")
    get root_path
    assert_select "html.dark"

    post theme_path("system")
    get root_path

    assert_select "html.dark", 0
    assert_select "html.light", 0
    assert_nil session[:theme]
  end

  test "an unknown palette is not a route" do
    # 404 rather than a raise: `show_exceptions` is :rescuable in test, so the
    # routing error is rendered the way production renders it.
    post "/theme/sepia"

    assert_response :not_found
    assert_nil session[:theme]
  end

  test "the selector ships on the landing page and the app, but not auth screens" do
    get root_path
    assert_theme_toggle

    get login_path
    assert_response :success
    assert_select "[data-preference=theme]", count: 0
    assert_select "[data-preference=language]", count: 0

    sign_in_as users(:one)
    get progress_path
    assert_theme_toggle
    assert_select "[data-rail=session-actions] > [data-preference=theme]", count: 0
    assert_select "[data-menu=account] [data-preference=theme]", count: 1
    assert_select "[data-menu=account] [data-preference=language]", count: 1
  end

  test "the toggle marks the current choice for a screen reader" do
    post theme_path("dark")
    get root_path

    assert_select "form[action=?] button[aria-current=true]", theme_path("dark")
    assert_select "form[action=?] button[aria-current=true]", theme_path("light"), 0
  end

  test "an untouched visitor has system selected" do
    get root_path

    assert_select "form[action=?] button[aria-current=true]", theme_path("system")
  end

  test "the choice is a POST, so hovering a prefetched link cannot repaint the app" do
    get "/theme/dark"

    assert_response :not_found
    assert_nil session[:theme]
  end

  test "the toggle is labelled in the reader's language" do
    get root_path

    assert_select "[aria-label=?]", I18n.t("chrome.theme_label", locale: :th)
    assert_select "form[action=?] button", theme_path("dark"),
                  text: /#{I18n.t("chrome.theme.dark", locale: :th)}/
  end

  test "the current theme opens a dropdown containing all three choices" do
    get root_path

    assert_select "[data-preference=theme][data-controller=dropdown]" do
      assert_select "button[aria-haspopup=true][aria-expanded=false]",
                    text: /#{I18n.t("chrome.theme.system")}/
      assert_select "[data-dropdown-target=panel][hidden][data-state=closed]" do
        assert_select "form", count: 3
      end
    end
  end

  test "the public navbar places both preferences after sign up" do
    get root_path

    signup = response.body.index(%(href="#{register_path}"))
    language = response.body.index(%(data-preference="language"))
    theme = response.body.index(%(data-preference="theme"))

    assert signup < language, "language should follow sign up"
    assert language < theme, "theme should follow language"
  end

  private
    def assert_theme_toggle
      assert_response :success
      assert_select "form[action=?]", theme_path("dark"), 1
      assert_select "form[action=?]", theme_path("light"), 1
      assert_select "form[action=?]", theme_path("system"), 1
    end
end
