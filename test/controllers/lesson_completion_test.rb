require "test_helper"

# The seam between the lesson's in-browser grading and the record: the exercise
# and the coding task each report a pass here.
class LessonCompletionTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "passing the exercise records the lesson's topic as learned" do
    assert_difference -> { users(:one).topic_completions.count }, 1 do
      post complete_lesson_url, params: { kind: "learned" }, as: :json
    end

    assert_response :created

    completion = users(:one).topic_completions.sole
    assert_equal LessonContent::COURSE_CODE, completion.course_code
    assert_equal LessonContent::TOPIC_KEY, completion.topic_key
    assert_not_predicate completion, :applied?
  end

  test "passing the coding task marks the same topic applied" do
    post complete_lesson_url, params: { kind: "learned" }, as: :json

    assert_no_difference -> { users(:one).topic_completions.count } do
      post complete_lesson_url, params: { kind: "applied" }, as: :json
    end

    assert_predicate users(:one).topic_completions.sole, :applied?
  end

  test "reporting the same pass twice records it once" do
    2.times { post complete_lesson_url, params: { kind: "learned" }, as: :json }

    assert_equal 1, users(:one).topic_completions.count
  end

  test "a kind the lesson does not hand out is refused" do
    assert_no_difference -> { TopicCompletion.count } do
      post complete_lesson_url, params: { kind: "cheated" }, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "recording requires a session" do
    sign_out
    post complete_lesson_url, params: { kind: "learned" }, as: :json

    assert_redirected_to login_path
    assert_equal 0, TopicCompletion.count
  end

  test "the record shows up on the screens that count it" do
    post complete_lesson_url, params: { kind: "applied" }, as: :json

    get my_learning_url
    assert_select "[data-panel=progress] summary",
                  text: /#{Regexp.escape(I18n.t("catalog.courses.AI1101.title"))}/

    get root_url
    assert_select "main", text: /#{Regexp.escape(I18n.t("units.topics_learned", done: 1, total: Syllabus.topic_count))}/

    get progress_url
    assert_select "h1", text: I18n.t("progress.greeting", name: users(:one).first_name)
    # One topic, learned and applied today: a one-day streak and the XP for both.
    assert_select "p", text: I18n.t("progress.subtitle", count: 1)
    assert_select "main", text: /#{LearnerProgress::XP_PER_LEARNED + LearnerProgress::XP_PER_APPLIED}/
  end
end
