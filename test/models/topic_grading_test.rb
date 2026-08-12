require "test_helper"

# The answer key. REAL_TOPIC_KEYS and TOPIC_GRADING are two frozen constants that
# have to stay in step, and `TOPIC_GRADING.fetch(key)` is what links them — so a
# topic added to one and not the other is a KeyError the first learner finds.
#
# Nothing here changes how grading behaves. It pins the three ways the table can
# be wrong, each of which is introduced by a code change and none of which any
# existing test would notice.
class TopicGradingTest < ActiveSupport::TestCase
  GRADING = LessonContent::TOPIC_GRADING

  test "every real topic has an entry, and every entry is a real topic" do
    assert_equal LessonContent::REAL_TOPIC_KEYS.sort, GRADING.keys.sort,
      "a topic in one constant and not the other raises KeyError when somebody opens it"
  end

  # An empty check list grades every submission as a pass — `[].all?` is true —
  # and then divides by zero working out the score, so the learner who triggers
  # it is credited and then shown a 500. LessonContent.percent guards the
  # default path against exactly this; the real-topic path does not.
  test "every topic is graded against at least one check" do
    empty = GRADING.reject { |_key, grading| grading[:checks].present? }.keys

    assert_empty empty, "these topics would pass any submission and then fail to score it: #{empty.join(', ')}"
  end

  # The recorded solution is what a learner is shown when they give up. If it
  # does not satisfy the topic's own checks, the answer the course calls correct
  # is one the course marks wrong.
  test "every recorded solution passes its own topic's checks" do
    failing = GRADING.filter_map do |key, grading|
      solution = grading.fetch(:solution).to_s
      missed = grading.fetch(:checks).reject { |check| solution.match?(check) }
      next if missed.empty? && solution.exclude?(LessonContent::BLANK)

      "#{key} (#{missed.length} unmet)"
    end

    assert_empty failing, "the course's own answer would be marked wrong for: #{failing.join(', ')}"
  end

  test "every topic's correct option is a plausible index" do
    invalid = GRADING.reject { |_key, grading| grading[:correct_option].is_a?(Integer) && grading[:correct_option] >= 0 }

    assert_empty invalid.keys, "a non-index correct_option never matches an answer: #{invalid.keys.join(', ')}"
  end
end
