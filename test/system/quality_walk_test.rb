require "application_system_test_case"

class QualityWalkTest < ApplicationSystemTestCase
  test "learner critical surfaces retain semantic landmarks" do
    sign_in_through_the_form(users(:one))

    paths = [
      root_path,
      course_path("AI1101"),
      lesson_path(course: "AI1101", topic: Syllabus.topic_keys("AI1101").first),
      my_learning_path,
      progress_path
    ]

    paths.each do |path|
      visit path
      assert_selector "main", count: 1, wait: 10
      assert_selector "h1", count: 1, wait: 10
    end
  end
end
