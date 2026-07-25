require "test_helper"

# The footer is shared chrome — it closes every screen, signed in or out — but
# its first two link columns are not shared: signed out they are anchors into
# the landing page's sections, signed in they point at the app's own screens.
# These tests guard that branch and the locale wiring behind it, in both
# locales, since a `#learn` anchor on /progress would scroll nowhere.
class FooterTest < ActionDispatch::IntegrationTest
  # Signed in as an admin below, since /instructor and /admin are role-gated and
  # admin is the one role that can open every screen. `/` is missing on purpose:
  # it redirects an admin to /admin, so the catalog is checked as a student.
  APP_SCREENS = %w[/my-learning /courses/AI1101 /lesson /map /progress /leaderboard /instructor /admin]

  # Nine column links plus the two policy links in the bottom bar.
  FOOTER_LINKS = 11

  test "signed out the footer links into the landing page" do
    each_locale do |locale|
      get root_path

      assert_response :success
      assert_select "footer", 1
      assert_select "footer a", FOOTER_LINKS
      assert_select "footer a[href='#learn']", 1
      assert_select "footer a[href='https://utcc.ac.th']", 1

      assert_footer_copy locale, "chrome.footer.columns.start.title"
    end
  end

  test "signed in every screen ends on a footer pointing at the app" do
    sign_in_as users(:admin)

    each_locale do |locale|
      APP_SCREENS.each { assert_app_footer(it) }

      assert_footer_copy locale, "chrome.footer.columns.learn.title"
    end
  end

  test "the catalog ends on the same footer" do
    sign_in_as users(:one)

    assert_app_footer "/"
  end

  private
    def assert_app_footer(path)
      get path

      assert_response :success, path
      assert_select "footer", 1, path
      assert_select "footer a", FOOTER_LINKS, path
      assert_select "footer a[href='#learn']", 0, path
      assert_select "footer a[href='#{knowledge_map_path}']", 1, path
      assert_select "footer a[href='#{progress_path}']", 1, path
      assert_select "footer a[href='https://utcc.ac.th']", 1, path
    end

    def each_locale
      %w[th en].each do |locale|
        post language_path(locale)
        yield locale
      end
    end

    # Every column title and link label resolves, and the tagline is the one
    # for the locale actually in the session rather than the fallback.
    def assert_footer_copy(locale, column_title_key)
      refute_includes response.body, "translation missing"

      I18n.with_locale(locale) do
        assert_includes response.body, I18n.t(column_title_key)
        assert_includes response.body, I18n.t("chrome.footer.tagline")
        assert_includes response.body, I18n.t("chrome.footer.rights")
        assert_includes response.body, I18n.t("chrome.footer.terms")
      end
    end
end
