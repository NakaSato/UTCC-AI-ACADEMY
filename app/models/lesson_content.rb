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
  REAL_TOPIC_KEYS = %w[1-1 1-2 1-3 2-1 2-2 2-3 2-4 3-1 3-2 4-1 4-2 5-1].freeze
  REAL_TOPIC_KEY = REAL_TOPIC_KEYS.first

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

  TOPIC_GRADING = {
    "1-1" => {
      correct_option: 1,
      checks: [
        /def\s+classify_risk/,
        /score\s*>=\s*0\.7/,
        /return\s+["']high["']/
      ],
      solution: "def classify_risk(score):\n    if score >= 0.7:\n        return \"high\"\n    return \"low\""
    },
    "1-2" => {
      correct_option: 0,
      checks: [
        /df\s*\[\s*[\"']age[\"']\s*\]/,
        /astype\s*\(\s*[\"']float[\"']\s*\)/,
        /df\.dtypes/
      ],
      solution: "df[\"age\"] = df[\"age\"].astype(\"float\")\nprint(df.dtypes)"
    },
    "1-3" => {
      correct_option: 0,
      checks: [
        /df\s*\[\s*[\"']email[\"']\s*\]/,
        /\.notna\s*\(\s*\)/,
        /\.mean\s*\(\s*\)/
      ],
      solution: "completeness = df[\"email\"].notna().mean()\nprint(completeness)"
    },
    "2-1" => {
      correct_option: 1,
      checks: [
        /weight\s*=\s*weight/,
        /-\s*learning_rate/,
        /\*\s*gradient/
      ],
      solution: "weight = weight - learning_rate * gradient\nprint(weight)"
    },
    "2-2" => {
      correct_option: 2,
      checks: [
        /mae\s*=/,
        /np\.abs\s*\(/,
        /\.mean\s*\(\s*\)/
      ],
      solution: "mae = np.abs(y_true - y_pred).mean()\nprint(mae)"
    },
    "2-3" => {
      correct_option: 1,
      checks: [
        /KMeans\s*\(/,
        /n_clusters\s*=\s*3/,
        /random_state\s*=\s*42/
      ],
      solution: "model = KMeans(n_clusters=3, random_state=42)\nlabels = model.fit_predict(X)"
    },
    "2-4" => {
      correct_option: 0,
      checks: [
        /Ridge\s*\(/,
        /alpha\s*=\s*1\.0/,
        /\.fit\s*\(\s*X_train\s*,\s*y_train\s*\)/
      ],
      solution: "model = Ridge(alpha=1.0)\nmodel.fit(X_train, y_train)"
    },
    "3-1" => {
      correct_option: 2,
      checks: [
        /pd\.read_csv\s*\(/,
        /dropna\s*\(/,
        /df\.columns/
      ],
      solution: "df = pd.read_csv(\"customers.csv\")\ndf = df.dropna(subset=[\"age\"])\nprint(df.columns)"
    },
    "3-2" => {
      correct_option: 0,
      checks: [
        /\.fit\s*\(\s*X_train\s*,\s*y_train\s*\)/,
        /\.score\s*\(\s*X_test\s*,\s*y_test\s*\)/,
        /score\s*=/
      ],
      solution: "model.fit(X_train, y_train)\nscore = model.score(X_test, y_test)\nprint(score)"
    },
    "4-1" => {
      correct_option: 1,
      checks: [
        /total_tokens\s*=/,
        /prompt_tokens\s*\+/,
        /max_new_tokens/
      ],
      solution: "total_tokens = prompt_tokens + max_new_tokens\nprint(total_tokens)"
    },
    "4-2" => {
      correct_option: 0,
      checks: [
        /Task:\s*\S/,
        /Context:\s*\S/,
        /Output\s+format:\s*\S/
      ],
      solution: "prompt = \"Task: summarize the customer feedback.\\nContext: use only the provided feedback.\\nOutput format: three bullet points.\"\nprint(prompt)"
    },
    "5-1" => {
      correct_option: 0,
      checks: [
        /annual_net_value\s*=/,
        /annual_net_value\s*=\s*annual_benefit/,
        /annual_net_value\s*=\s*annual_benefit\s*-\s*annual_cost/
      ],
      solution: "annual_net_value = annual_benefit - annual_cost\nprint(annual_net_value)"
    }
  }.freeze

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

  # A backslash command or a `$…$` pair. Nothing else counts: `w_{new}` is TeX
  # syntax and is also just how somebody writes a subscript in a sentence, and
  # twelve of the thirteen equation blocks are prose formulas that would be
  # ruined by a typesetter — "input + model → output → evaluation" rendered as
  # maths is a row of italic variables.
  LATEX = /\\[a-zA-Z]+|\$[^$]+\$/

  Block = Data.define(:type, :extra, :position, :definition) do
    def value = definition.translate("theory.blocks")[position]

    # Whether this block is typeset or printed. The lesson view asks; a block
    # that is LaTeX gets KaTeX, and one that is not is left exactly as written.
    #
    # The alternative was to make the *type* decide, which would have meant a
    # second block type and a migration of copy that is already correct. The
    # content is the honest signal here: an author writing `\lceil` means maths,
    # and an author writing an arrow means a sentence.
    def latex? = type == :equation && LessonContent::LATEX.match?(value.to_s)

    # An image block only renders once its `extra` is a real URL, matching the
    # design — a caption with no source would otherwise draw an empty plate.
    def image? = type == :image && extra.to_s.match?(%r{\Ahttps?://\S+\z})
  end

  TopicDefinition = Data.define(:key) do
    def real? = LessonContent::REAL_TOPIC_KEYS.include?(key.to_s)

    def step_for(param) = LessonContent.step_for(param)
    def step_number(step) = LessonContent.step_number(step)
    def percent_for(step) = LessonContent.percent_for(step)
    def step_label(step) = LessonContent.step_label(step)
    def rewards = LessonContent.rewards

    def translate(path)
      scoped = "lesson.topics.topic_#{key.tr('-', '_')}.#{path}"
      I18n.exists?(scoped) ? I18n.t(scoped) : I18n.t("lesson.#{path}")
    end

    def blocks
      BLOCKS.each_with_index.map do |attrs, position|
        Block.new(type: attrs[:type], extra: attrs[:extra], position:, definition: self)
      end
    end

    def options
      return LessonContent.options unless real?

      translate("quiz.options").each_with_index.map do |text, index|
        { key: translate("quiz.keys")[index], text: }
      end
    end

    def checks = real? ? translate("code.checks") : LessonContent.checks
    def starter_code = real? ? translate("code.starter") : STARTER_CODE
    def correct_option = real? ? TOPIC_GRADING.fetch(key).fetch(:correct_option) : CORRECT_OPTION
    def solution = real? ? TOPIC_GRADING.fetch(key).fetch(:solution) : "train_test_split(X, y, test_size=0.2, random_state=42)"

    def grade_quiz(answer)
      passed = answer.to_s == correct_option.to_s
      { passed:, score: passed ? 100 : 0, gems: QUIZ_GEMS, correct_index: correct_option }
    end

    def grade_code(source)
      return LessonContent.grade_code(source) unless real?

      results = TOPIC_GRADING.fetch(key).fetch(:checks).map { source.to_s.match?(it) }

      { passed: results.all? && source.to_s.exclude?(BLANK),
        score: (results.count(true) * 100.0 / results.size).round,
        checks: results, gems: CODE_GEMS }
    end
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
      LessonContent.for(nil).blocks
    end

    def for(topic_key) = TopicDefinition.new(key: topic_key.to_s)

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
