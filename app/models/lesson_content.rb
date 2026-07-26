# The four-step lesson: theory, exercise, coding task, summary.
#
# **Grading is on the server.** `CORRECT_OPTION` and `CHECKS` are read by
# `grade_quiz` and `grade_code` and never rendered into the page, so the answer
# key and the passing regexes are no longer public and a pass cannot be claimed
# by posting one. The browser sends what the student did and renders the verdict
# it gets back — one round trip, so the design's instant feedback survives.
#
# The cost is that the coding task's criteria no longer tick as you type: they
# light up when "Run & check" answers. Live ticking needs the patterns in the
# page, which is the whole thing this moved to close.
module LessonContent
  STEPS = %i[ theory exercise code summary ].freeze

  # A lesson is a position in a syllabus: `?course=AI1101&topic=2-3`. The prose,
  # the quiz and the coding task below are the same whichever topic is open —
  # writing sixteen of each is a content job, not a modelling one — but the
  # identity is real, so a completion is filed against the topic the student was
  # actually on.
  #
  # Without a course the lesson is about the one every student starts on; without
  # a topic it is about the next one they have not finished.
  DEFAULT_COURSE = "AI1101"

  # How full the top progress bar is on each step.
  STEP_PERCENT = { theory: 12, exercise: 42, code: 74, summary: 100 }.freeze

  # Index of the correct exercise option — "Unsupervised Learning — Clustering".
  # Server-side only: nothing renders this, and `grade_quiz` is the only reader.
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

  # Each criterion is a pattern the submitted source has to match. Server-side
  # only, like the answer key — the page renders the labels beside them, never
  # the patterns.
  CHECKS = [
    /train_test_split\s*\(/,
    /test_size\s*=\s*0\.2/,
    /random_state\s*=\s*42/
  ].freeze

  # The starter code ships with blanks in it. Leaving one in is a fail however
  # well the rest matches, so a student cannot pass by pasting the criteria
  # around an unfinished line.
  BLANK = "___".freeze

  # What each graded step is worth. Taken from LearnerProgress rather than
  # written twice: these used to be a literal here and a Stimulus default in the
  # page, kept in step by hand, and the counter the student watches has to agree
  # with the XP the progress screens count.
  QUIZ_GEMS = LearnerProgress::GEMS_PER_LEARNED
  CODE_GEMS = LearnerProgress::GEMS_PER_APPLIED

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

    # Labels only. The patterns behind them stay on this side of the wire.
    def checks = I18n.t("lesson.code.checks")

    # ---- Grading ------------------------------------------------------------
    # Both answer with a plain hash, which is what the controller renders and
    # what the Stimulus controllers read. `checks` is per-criterion so the coding
    # task can light its list from the verdict rather than from a local guess.

    # `correct_index` comes back so the page can mark the right option, which is
    # what the design does once an answer is in. It is revealed in answer to a
    # graded, recorded attempt rather than sitting in the page beforehand — a
    # student can still learn it by guessing, but not without leaving a failed
    # submission behind, which is the row the instructor report wants anyway.
    # `score` is the share of the step's criteria that matched, which for one
    # right answer is 0 or 100. The page ignores it — it is kept on the row so
    # the Teaching console has something to average that is not a pass rate.
    def grade_quiz(answer)
      passed = answer.to_s == CORRECT_OPTION.to_s

      { passed:, score: passed ? 100 : 0, gems: QUIZ_GEMS, correct_index: CORRECT_OPTION }
    end

    # Partial credit even on a fail: how close a student got is the thing worth
    # measuring, and these three booleans are the only granularity the app has.
    # The leftover blank still fails the attempt outright — it just does not zero
    # what did match.
    def grade_code(source)
      results = CHECKS.map { source.to_s.match?(it) }

      { passed: results.all? && source.to_s.exclude?(BLANK),
        score: percent(results.count(true), results.size), checks: results, gems: CODE_GEMS }
    end

    def rewards
      [
        { value: "+#{REWARD_GEMS}",  label: I18n.t("lesson.done.rewards.gems") },
        { value: "+#{REWARD_XP}",    label: "XP" },
        { value: REWARD_STREAK.to_s, label: I18n.t("lesson.done.rewards.streak") }
      ]
    end

    private
      def percent(part, whole) = whole.zero? ? 0 : (part * 100.0 / whole).round
  end
end
