require "test_helper"

# The seam between the lesson and the record. The browser sends what the student
# did; the server decides. The cases that matter most are the ones that used to
# be impossible to enforce — a claimed pass, and a pass at a locked topic.
class LessonCompletionTest < ActionDispatch::IntegrationTest
  TOPIC_CONTENT = LessonContent.for("1-1")
  RIGHT_ANSWER = TOPIC_CONTENT.correct_option
  WRONG_ANSWER = TOPIC_CONTENT.correct_option + 1
  GOOD_CODE = TOPIC_CONTENT.solution

  # A method, not a constant. The syllabus is a table now, and a constant in the
  # class body is evaluated when the file loads — before fixtures are inserted,
  # so `topic` would freeze as nil and every post here would come back 403 for a
  # topic that does not exist.
  def topic_params = { course: LessonContent::DEFAULT_COURSE, topic: Syllabus.topic_keys.first }

  setup { sign_in_as users(:one) }

  test "a right answer is graded, recorded, and earns the topic" do
    assert_difference -> { users(:one).topic_completions.count }, 1 do
      submit(kind: "quiz", answer: RIGHT_ANSWER)
    end

    assert_response :success
    assert response.parsed_body["passed"]

    completion = users(:one).topic_completions.sole
    assert_equal topic_params[:course], completion.course_code
    assert_equal topic_params[:topic], completion.topic_key
    assert_not_predicate completion, :applied?
  end

  # The point of the whole change: saying you passed is not passing.
  test "a wrong answer earns nothing, however it is posted" do
    assert_no_difference -> { TopicCompletion.count } do
      submit(kind: "quiz", answer: WRONG_ANSWER)
    end

    assert_response :success
    assert_not response.parsed_body["passed"]
  end

  test "a claimed pass is not a pass — the verdict is the server's" do
    assert_no_difference -> { TopicCompletion.count } do
      post submit_lesson_url,
           params: { kind: "quiz", answer: WRONG_ANSWER, passed: true, **topic_params }, as: :json
    end

    assert_not response.parsed_body["passed"]
  end

  test "the attempt is kept even when it fails" do
    assert_difference -> { Submission.count }, 1 do
      submit(kind: "quiz", answer: WRONG_ANSWER)
    end

    assert_not_predicate Submission.sole, :passed?
  end

  # The grader scores the attempt and the controller has to carry that to the
  # row — a score that stops being passed through would leave the Teaching
  # console averaging nothing, with no other screen to notice.
  test "the score the grader worked out reaches the row" do
    submit(kind: "quiz", answer: WRONG_ANSWER)
    assert_equal 0, Submission.sole.score

    submit(kind: "quiz", answer: RIGHT_ANSWER)
    assert_equal 100, Submission.newest_first.first.score
  end

  test "a partly correct coding task is scored for what matched" do
    submit(kind: "code", answer: "def classify_risk(score):")

    assert_not_predicate Submission.sole, :passed?
    assert_equal 33, Submission.sole.score
  end

  test "the answer key is not in the page" do
    get lesson_url(course: topic_params[:course], step: "exercise")

    assert_response :success
    assert_no_match(/correct-index/, response.body)
  end

  test "the passing patterns are not in the page" do
    get lesson_url(course: topic_params[:course], step: "code")

    assert_response :success
    assert_no_match(/patterns-value/, response.body)
    assert_no_match(/random_state\\s/, response.body)
  end

  test "the coding task reports each criterion" do
    submit(kind: "code", answer: "x = 1")

    assert_equal [ false, false, false ], response.parsed_body["checks"]
    assert_not response.parsed_body["passed"]
  end

  test "passing the coding task marks the same topic applied" do
    submit(kind: "quiz", answer: RIGHT_ANSWER)

    assert_no_difference -> { users(:one).topic_completions.count } do
      submit(kind: "code", answer: GOOD_CODE)
    end

    assert_predicate users(:one).topic_completions.sole, :applied?
  end

  test "a topic in a module that is still locked is refused" do
    assert_no_difference -> { Submission.count } do
      post submit_lesson_url,
           params: { kind: "quiz", answer: RIGHT_ANSWER,
                     course: topic_params[:course], topic: Syllabus.keys_in(3).first }, as: :json
    end

    assert_response :forbidden
  end

  test "a topic that is not in the syllabus is refused" do
    assert_no_difference -> { Submission.count } do
      post submit_lesson_url,
           params: { kind: "quiz", answer: RIGHT_ANSWER,
                     course: topic_params[:course], topic: "99-9" }, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "finishing a module opens the next one" do
    Syllabus.keys_in(1).each do |key|
      post submit_lesson_url,
           params: { kind: "quiz", answer: LessonContent.for(key).correct_option,
                     course: topic_params[:course], topic: key }, as: :json
    end

    post submit_lesson_url,
         params: { kind: "quiz", answer: LessonContent.for(Syllabus.keys_in(2).first).correct_option,
                   course: topic_params[:course], topic: Syllabus.keys_in(2).first }, as: :json

    assert_response :success
    assert response.parsed_body["passed"]
  end

  test "reporting the same pass twice records it once" do
    2.times { submit(kind: "quiz", answer: RIGHT_ANSWER) }

    assert_equal 1, users(:one).topic_completions.count
    assert_equal 2, Submission.count, "both attempts are kept"
  end

  test "a kind the lesson does not hand out is refused" do
    assert_no_difference -> { Submission.count } do
      submit(kind: "cheated", answer: RIGHT_ANSWER)
    end

    assert_response :unprocessable_entity
  end

  # Where a signed-out visitor is sent is app_screens_test's subject, not this
  # one's — asserted as "not graded" so a change to that redirect cannot fail a
  # test about recording.
  test "recording requires a session" do
    sign_out
    submit(kind: "quiz", answer: RIGHT_ANSWER)

    assert_response :redirect
    assert_equal 0, TopicCompletion.count
    assert_equal 0, Submission.count
  end

  test "the record shows up on the screens that count it" do
    submit(kind: "quiz", answer: RIGHT_ANSWER)
    submit(kind: "code", answer: GOOD_CODE)

    get my_learning_url
    assert_select "[data-panel=progress] summary",
                  text: /#{Regexp.escape(I18n.t("catalog.courses.AI1101.title"))}/

    get root_url
    assert_select "main", text: /#{Regexp.escape(I18n.t("units.topics_learned", done: 1, total: Syllabus.topic_count))}/
  end

  private
    def submit(kind:, answer:)
      post submit_lesson_url, params: { kind:, answer:, **topic_params }, as: :json
    end
end
