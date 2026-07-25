# The four-step lesson: theory, exercise, coding task, summary.
#
# The exercise and the coding task are graded in the browser (see the `quiz` and
# `code_task` Stimulus controllers) so the design's instant feedback survives.
# The answer key and the passing regexes are therefore public — which is fine
# for a teaching exercise, and is what the design does. Real grading belongs on
# the server once submissions are persisted.
module LessonContent
  STEPS = %i[ theory exercise code summary ].freeze

  # How full the top progress bar is on each step.
  STEP_PERCENT = { theory: 12, exercise: 42, code: 74, summary: 100 }.freeze

  # Index of the correct exercise option — "Unsupervised Learning — Clustering".
  CORRECT_OPTION = 1

  OPTIONS = [
    "Supervised Learning — Classification",
    "Unsupervised Learning — Clustering",
    "Supervised Learning — Regression",
    "Reinforcement Learning"
  ].freeze

  STARTER_CODE = <<~PYTHON.freeze
    from sklearn.model_selection import train_test_split

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=___, random_state=___
    )

    print(len(X_train), len(X_test))
  PYTHON

  # Each criterion is a source pattern the browser re-creates as a RegExp.
  CHECKS = [
    'train_test_split\s*\(',
    'test_size\s*=\s*0\.2',
    'random_state\s*=\s*42'
  ].freeze

  REWARD_GEMS = 15
  REWARD_XP = 120
  REWARD_STREAK = 13

  # The theory step's free-form content, appended after the fixed introduction.
  # `type` and `extra` are shape; the prose is `lesson.theory.blocks` in the
  # locale files, joined BY INDEX — insert a row here and you must insert one
  # there, in both locales, or every block after it renders the wrong copy.
  # `placeholder_content_test.rb` asserts the two stay the same length.
  BLOCK_TYPES = %i[ heading text callout equation code link image ].freeze

  BLOCKS = [
    { type: :callout },
    { type: :equation },
    { type: :code, extra: "Python" },
    { type: :link, extra: "https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.train_test_split.html" }
  ].freeze

  Block = Data.define(:type, :extra, :position) do
    def value = I18n.t("lesson.theory.blocks")[position]

    # An image block only renders once its `extra` is a real URL, matching the
    # design — a caption with no source would otherwise draw an empty plate.
    def image? = type == :image && extra.to_s.match?(%r{\Ahttps?://\S+\z})
  end

  class << self
    def step_for(param)
      STEPS.include?(param.to_s.to_sym) ? param.to_s.to_sym : STEPS.first
    end

    def step_number(step) = STEPS.index(step) + 1

    def percent_for(step) = STEP_PERCENT.fetch(step)

    def step_label(step)
      I18n.t("lesson.step_of",
             current: step_number(step), total: STEPS.size,
             name: I18n.t("lesson.steps.#{step}"))
    end

    def blocks
      BLOCKS.each_with_index.map do |attrs, position|
        Block.new(type: attrs[:type], extra: attrs[:extra], position:)
      end
    end

    def options
      keys = I18n.t("lesson.quiz.keys")
      OPTIONS.each_with_index.map { |text, index| { key: keys[index], text: } }
    end

    def checks
      labels = I18n.t("lesson.code.checks")
      CHECKS.each_with_index.map { |pattern, index| { pattern:, label: labels[index] } }
    end

    def rewards
      [
        { value: "+#{REWARD_GEMS}",  label: I18n.t("lesson.done.rewards.gems") },
        { value: "+#{REWARD_XP}",    label: "XP" },
        { value: REWARD_STREAK.to_s, label: I18n.t("lesson.done.rewards.streak") }
      ]
    end
  end
end
