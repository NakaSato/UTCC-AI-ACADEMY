require "application_system_test_case"

class AdminQueueWalkTest < ApplicationSystemTestCase
  test "an administrator sees a real course approval request" do
    visit "/login"
    fill_in "student_id", with: users(:admin).student_id
    fill_in "password", with: "password"
    find("input[type=submit]").click
    assert_current_path admin_path, wait: 10

    visit admin_path(tab: :courses)
    within "[data-course-code='AI1101']" do
      click_button I18n.t("admin.courses.transition.archived")
    end

    assert_current_path admin_path(tab: :queue)
    assert_text I18n.t("admin.queue.status.pending")
    assert_text I18n.t("admin.queue.self_review")
  end
end
