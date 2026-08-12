require "application_system_test_case"

# Whether an equation is actually typeset, which is visible nowhere else.
#
# `app_screens_test.rb` asserts the server's half: a LaTeX block carries the
# controller and its source, a prose one does not. Neither of those proves KaTeX
# runs. Three ways it could fail with that test still green — the stylesheet not
# reaching the page, the vendored library not resolving through the import map,
# or `katex.render` throwing on the expression — and all three leave a learner
# reading `\lceil 0.8\,N \rceil` on a lesson page, which is what they saw before
# this was wired up at all.
class KatexWalkTest < ApplicationSystemTestCase
  test "a LaTeX equation block is typeset in the browser, and a prose one is left alone" do
    student = users(:one)
    # 5-2 is behind the progression gate; this test is about what it renders.
    Syllabus.topic_keys.take_while { it != "5-2" }.each do
      TopicCompletion.record(user: student, course_code: "AI1101", topic_key: it, kind: :learned)
    end

    sign_in_through_the_form(student)
    visit "/lesson?course=AI1101&topic=5-2&step=theory"

    # KaTeX replaces the source with its own markup, so the rendered element is
    # the proof — and the source is gone from the page rather than sitting under
    # it twice.
    assert_selector "[data-controller=katex] .katex", wait: 10
    assert_no_text '\lceil'

    # It is typeset rather than merely wrapped: KaTeX emits MathML beside the
    # HTML, which is what a screen reader reads.
    assert_selector "[data-controller=katex] .katex annotation", visible: :all

    # And the prose formula on a real topic is still prose.
    visit "/lesson?course=AI1101&topic=1-1&step=theory"

    assert_no_selector ".katex"
    assert_text LessonContent.for("1-1").blocks.find { it.type == :equation }.value
  end
end
