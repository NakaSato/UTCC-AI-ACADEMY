require "test_helper"

class LanguagesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "the app renders in Thai by default" do
    get root_url
    assert_select "h1", text: I18n.t("catalog.title", locale: :th)
  end

  test "switching to English sticks across requests" do
    post language_url(:en), headers: { "HTTP_REFERER" => root_url }
    assert_redirected_to root_url

    get root_url
    assert_select "html[lang=en]"
    assert_select "h1", text: I18n.t("catalog.title", locale: :en)

    get progress_url
    assert_select "h1", text: I18n.t("progress.greeting", name: users(:one).first_name, locale: :en)
  end

  test "switching back to Thai restores the default" do
    post language_url(:en), headers: { "HTTP_REFERER" => root_url }
    post language_url(:th), headers: { "HTTP_REFERER" => root_url }

    get root_url
    assert_select "html[lang=th]"
    assert_select "h1", text: I18n.t("catalog.title", locale: :th)
  end

  test "an unsupported locale is not routable" do
    post "/language/fr"

    # The route constraint rejects it, so nothing reaches the controller and
    # I18n.locale is never set to something outside available_locales.
    assert_response :not_found

    get root_url
    assert_select "html[lang=th]"
  end

  test "the toggle works without a session" do
    sign_out

    post language_url(:en), headers: { "HTTP_REFERER" => login_url }
    assert_redirected_to login_url

    get login_url
    assert_select "h1", text: I18n.t("auth.login.title", locale: :en)
  end

  test "the selected language opens a dropdown containing every locale" do
    get root_url

    assert_select "[data-menu=account] [data-preference=language][data-controller=dropdown]" do
      assert_select "button[aria-haspopup=true][aria-expanded=false]",
                    text: /#{I18n.t("language_full_name", locale: :th)}/
      assert_select "[data-dropdown-target=panel][hidden][data-state=closed]" do
        I18n.available_locales.each do |locale|
          assert_select "form[action=?] button", language_path(locale),
                        text: /#{I18n.t("language_full_name", locale:)}/
        end
      end
    end
  end
end
