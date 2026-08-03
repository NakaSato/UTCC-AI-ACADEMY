require "test_helper"

class CourseCurriculumControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "a course page renders its own module and topic shape" do
    get course_url("AI1102")

    assert_response :success
    assert_select "details", count: 2
    assert_select "main", text: /#{Regexp.escape(I18n.t("course.curricula.AI1102.modules")[0][:title])}/
    assert_select "a[href=?]", lesson_path(course: "AI1102", topic: "AI1102-1-1")
  end

  test "a lesson cannot use a topic key from another course" do
    get lesson_url(course: "AI1102", topic: "1-1")

    assert_redirected_to course_path("AI1102")
    assert_equal I18n.t("flash.topic_missing"), flash[:alert]

    post submit_lesson_url, params: { course: "AI1102", topic: "1-1", kind: "quiz", answer: "0" }, as: :json

    assert_response :unprocessable_entity
  end

  test "a course lesson opens its own first topic" do
    get lesson_url(course: "AI1102", topic: "AI1102-1-1")

    assert_response :success
    assert_select "main[data-lesson-course=?][data-lesson-topic=?]", "AI1102", "AI1102-1-1"
  end

  test "grading an AI1102 lesson records completion in AI1102" do
    post submit_lesson_url,
         params: { course: "AI1102", topic: "AI1102-1-1", kind: "quiz", answer: "1" }, as: :json

    assert_response :success
    assert response.parsed_body["passed"]

    completion = users(:one).topic_completions.sole
    assert_equal "AI1102", completion.course_code
    assert_equal "AI1102-1-1", completion.topic_key
    assert_empty TopicCompletion.where(course: Course.find_by!(code: "AI1101"))
  end

  test "course-specific module locking advances after that course's completions" do
    second_module_key = Syllabus.keys_in(2, "AI1102").first

    get course_url("AI1102")
    assert_select "details[open]", count: 1
    assert_select "a[href=?]", lesson_path(course: "AI1102", topic: second_module_key), count: 0

    get lesson_url(course: "AI1102", topic: second_module_key)
    assert_redirected_to course_path("AI1102")
    assert_equal I18n.t("flash.topic_locked"), flash[:alert]

    Syllabus.keys_in(1, "AI1102").each do |key|
      TopicCompletion.record(user: users(:one), course_code: "AI1102", topic_key: key, kind: :learned)
    end

    get course_url("AI1102")
    assert_select "details[open]", count: 1
    assert_select "a[href=?]", lesson_path(course: "AI1102", topic: second_module_key)
  end
end
