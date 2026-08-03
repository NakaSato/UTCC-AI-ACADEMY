require "application_system_test_case"

class AdminCoursesWalkTest < ApplicationSystemTestCase
  test "an administrator sees real course counts and can archive a course" do
    visit "/login"
    fill_in "student_id", with: users(:admin).student_id
    fill_in "password", with: "password"
    find("input[type=submit]").click
    assert_current_path admin_path, wait: 10

    visit admin_path(tab: :courses)

    assert_text I18n.t("catalog.courses.AI1101.title")
    assert_text I18n.t("admin.courses.state.published")
    within "[data-course-code='AI1101']" do
      click_button I18n.t("admin.courses.transition.archived")
    end

    assert_text I18n.t("admin.courses.state.archived")
  end
end
