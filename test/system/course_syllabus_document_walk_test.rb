require "application_system_test_case"

class CourseSyllabusDocumentWalkTest < ApplicationSystemTestCase
  test "a learner can reach each course's syllabus document" do
    sign_in_through_the_form(users(:one))

    visit course_path("AI1101")
    assert_link I18n.t("course.download_syllabus"), href: course_syllabus_path("AI1101")

    visit course_path("AI1102")
    assert_link I18n.t("course.download_syllabus"), href: course_syllabus_path("AI1102")
  end
end
