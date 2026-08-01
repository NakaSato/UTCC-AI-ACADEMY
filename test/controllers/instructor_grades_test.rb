require "test_helper"

# The Teaching console's CSV download — the first inert button to become real.
class InstructorGradesTest < ActionDispatch::IntegrationTest
  test "staff download the roster as CSV, headed in the console's language" do
    sign_in_as users(:instructor)
    get instructor_grades_url

    assert_response :success
    assert_equal "text/csv; charset=utf-8", response.media_type + "; charset=utf-8"
    assert_match(/attachment/, response.headers["Content-Disposition"])
    assert_match(/grades-AI1101-BA-2-1-2569\.csv/, response.headers["Content-Disposition"])

    body = response.body
    assert body.start_with?("﻿"), "Excel needs the BOM or Thai names turn to mojibake"
    assert_includes body, I18n.t("instructor.th_progress")
    assert_includes body, users(:one).name
    assert_includes body, users(:one).student_id
  end

  test "the rows carry the same figures the screen shows" do
    TopicCompletion.record(user: users(:one), course_code: "AI1101",
                           topic_key: Syllabus.topic_keys.first, kind: :learned)

    sign_in_as users(:instructor)
    get instructor_grades_url

    percent = (1 * 100.0 / Syllabus.topic_count).round
    assert_match(/#{users(:one).student_id},#{users(:one).name},#{percent}%/, response.body)
  end

  test "a field with a comma in it is quoted, not split" do
    users(:one).update!(name: "สมชาย, จูเนียร์")

    sign_in_as users(:instructor)
    get instructor_grades_url

    assert_includes response.body, '"สมชาย, จูเนียร์"'
  end

  test "a student is turned away like the screen itself" do
    sign_in_as users(:one)
    get instructor_grades_url

    assert_response :redirect
    assert_equal 0, response.body.bytesize
  end

  test "an unassigned instructor sees the empty state, not another section's roster" do
    instructor = unassigned_instructor

    sign_in_as instructor
    get instructor_url

    assert_response :success
    assert_includes response.body, I18n.t("instructor.no_section.title")
    assert_not_includes response.body, users(:one).student_id
    assert_not_includes response.body, I18n.t("instructor.export_csv")
  end

  test "an unassigned instructor cannot export another section's roster" do
    instructor = unassigned_instructor

    sign_in_as instructor
    get instructor_grades_url

    assert_redirected_to instructor_path
    follow_redirect!
    assert_includes response.body, I18n.t("instructor.no_section.title")
    assert_not_includes response.body, users(:one).student_id
  end

  private
    def unassigned_instructor
      User.create!(name: "Unassigned Instructor", student_id: "2011071730993",
                   password: "securePass1", role: :instructor)
    end
end
