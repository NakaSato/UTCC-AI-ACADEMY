require "application_system_test_case"

class AdminFeaturesWalkTest < ApplicationSystemTestCase
  test "an administrator toggles an approved feature in Thai" do
    visit "/login"
    fill_in "student_id", with: users(:admin).student_id
    fill_in "password", with: "password"
    find("input[type=submit]").click
    assert_current_path admin_path, wait: 10
    visit admin_path(tab: :features)

    assert_text I18n.t("admin.features.groups")[0][:items][0][:name]
    assert_text I18n.t("admin.features.groups")[0][:items][1][:name]
    assert_text I18n.t("admin.features.groups")[1][:items][0][:name]

    find("form[action='#{admin_feature_setting_path("leaderboard")}'] button[role=switch]").click

    assert_current_path admin_path(tab: :features), wait: 10
    assert_text I18n.t("flash.feature_setting_changed", name: I18n.t("admin.features.keys.leaderboard"),
                      state: I18n.t("admin.features.state.on"))
  end
end
