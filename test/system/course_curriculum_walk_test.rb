require "application_system_test_case"

class CourseCurriculumWalkTest < ApplicationSystemTestCase
  test "a learner can see two distinct course curricula" do
    sign_in_through_the_form(users(:one))

    visit course_path("AI1101")
    assert_selector "details", count: 6

    visit course_path("AI1102")
    assert_selector "details", count: 2
    assert_text I18n.t("course.curricula.AI1102.modules")[0][:title]
    assert_selector "a[href='#{lesson_path(course: "AI1102", topic: "AI1102-1-1")}']"
  end
end
