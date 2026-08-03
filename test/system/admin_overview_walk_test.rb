require "application_system_test_case"

class AdminOverviewWalkTest < ApplicationSystemTestCase
  test "an administrator sees live Overview counts without fabricated panels" do
    visit "/login"
    fill_in "student_id", with: users(:admin).student_id
    fill_in "password", with: "password"
    find("input[type=submit]").click
    assert_current_path admin_path, wait: 10

    visit admin_path(tab: :overview)

    assert_selector "h1", text: I18n.t("admin.title")
    assert_text I18n.t("admin.overview.stats")[0][:label]
    assert_text I18n.t("admin.overview.stats")[3][:label]
    assert_text I18n.t("admin.overview.live_note")
    assert_no_text "Adoption by faculty"
    assert_no_text "Recent activity"
    assert_no_text "Service health"
  end
end
