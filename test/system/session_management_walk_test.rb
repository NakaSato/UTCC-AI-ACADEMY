require "application_system_test_case"

class SessionManagementWalkTest < ApplicationSystemTestCase
  test "a learner can review and revoke another active session" do
    sign_in_through_the_form(users(:student))
    other = users(:student).sessions.create!(user_agent: "Mozilla/5.0 (Android)")

    visit profile_path

    assert_text I18n.t("profile.sessions.title", locale: :th)
    assert_text I18n.t("profile.sessions.devices.android", locale: :th)
    assert_button I18n.t("profile.sessions.revoke", locale: :th)

    find("button.session-revoke").click

    assert_text I18n.t("flash.session_revoked", locale: :th)
    assert_not Session.exists?(other.id)
  end
end
