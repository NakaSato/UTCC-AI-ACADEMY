require "application_system_test_case"

# The walk docs/process.md makes the definition of done: sign in, open a
# lesson, pass the graded step in a real browser, and see the pass counted on
# the screens that count it. This is the one place the whole seam runs end to
# end — the form, the Stimulus controllers, the fetch to lesson/submit, the
# server's verdict, and the record it leaves.
class LearningWalkTest < ApplicationSystemTestCase
  test "a student signs in, passes the exercise, and the pass is counted" do
    student = users(:one)
    sign_in_through_the_form(student)

    # Signed in, the root is the catalog.
    assert_selector "h1", text: I18n.t("catalog.title", locale: :th)

    # The first topic's exercise. The page must not carry the key or patterns —
    # that is the whole point of server-side grading.
    visit "/lesson?course=AI1101&topic=1-1&step=exercise"
    assert_no_selector "[data-quiz-correct-index-value]", visible: :all
    assert_no_selector "[data-code-task-patterns-value]", visible: :all

    # A wrong answer first: the server marks the pick wrong and reveals the
    # right option, and nothing is recorded.
    find("[data-quiz-target=option][data-index='0']").click
    click_button I18n.t("lesson.quiz.check", locale: :th)
    assert_selector "[data-quiz-target=feedback][data-state=wrong]"
    assert_selector "[data-quiz-target=option][data-state=correct]"
    assert_equal 0, student.topic_completions.count

    # Reload and answer right: the verdict comes back a pass, the next step
    # unlocks, and the completion exists.
    visit "/lesson?course=AI1101&topic=1-1&step=exercise"
    find("[data-quiz-target=option][data-index='#{LessonContent.for("1-1").correct_option}']").click
    click_button I18n.t("lesson.quiz.check", locale: :th)
    assert_selector "[data-quiz-target=feedback][data-state=correct]"
    assert_selector "a[data-quiz-target=next]"

    completion = student.topic_completions.sole
    assert_equal "1-1", completion.topic_key

    # The screens that count it agree.
    visit "/my-learning"
    assert_selector "[data-panel=progress] summary", text: I18n.t("catalog.courses.AI1101.title", locale: :th)
    assert_text I18n.t("my_learning.learned_count", done: 1, total: Syllabus.topic_count, locale: :th)
  end
end
