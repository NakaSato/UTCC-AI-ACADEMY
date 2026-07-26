# Placeholder course data until real models land — see README "Next steps".
# Everything a human reads lives in config/locales; only the numbers and the
# taxonomy live here, so swapping in a Course model means replacing `all`.
module CourseCatalog
  # The order here is the order of the filter chips on the catalog.
  FILTERS = %i[ all core popular ml genai data ethics ].freeze

  # `learned` and `applied` are the signed-in learner's own counts, filled in by
  # `for` from topic_completions and left at zero by `all`, which knows nothing
  # about a user. How much there is to do comes from Syllabus — every course
  # reuses the one placeholder syllabus, so the denominators are the same
  # everywhere until real modules land.
  Course = Data.define(
    :code, :credits, :rating, :projects, :hours, :level, :core, :certificate,
    :tags, :learners, :learned, :applied, :next_key
  ) do
    def topics = Syllabus.topic_count
    def applied_topics = Syllabus.applied_topic_count

    def title = I18n.t("catalog.courses.#{code}.title")
    def description = I18n.t("catalog.courses.#{code}.desc")
    def instructor = I18n.t("catalog.courses.#{code}.instructor")
    def level_name = I18n.t("levels.#{level}")

    # A course is started once anything in it has been finished — there is no
    # enrol button, so the first completed topic is the enrolment.
    def started? = learned.positive?
    def completed? = learned >= topics
    def percent = (learned * 100.0 / topics).round
    def applied_percent = (applied * 100.0 / applied_topics).round

    # The card's avatar plate. Both locales spell the instructor as an academic
    # title, a space, then the given name ("ผศ.ดร. ชนกานต์", "Asst. Prof.
    # Chanakan"), so the last word is the part worth abbreviating.
    def instructor_initials = instructor.split.last.to_s.first(2)

    def code_line = "#{code} · #{I18n.t('units.credits', count: credits)}"
    def projects_text = I18n.t("units.projects", count: projects)
    def hours_text = I18n.t("units.hours", count: hours)
    def learners_text = I18n.t("units.learners", count: learners)
    def progress_text = I18n.t("units.topics_learned", done: learned, total: topics)

    def tagged?(filter) = filter == :all || tags.include?(filter)

    # ---- My Learning and the dashboard ------------------------------------
    # The same value object serves all three progress screens, so a course reads
    # the same wherever it appears.

    def learned_percent = percent
    def in_progress? = !completed?
    def badge = I18n.t("my_learning.badge_state.#{completed? ? :done : :now}")
    def learned_text = I18n.t("my_learning.learned_count", done: learned, total: topics)
    def applied_text = I18n.t("my_learning.applied_count", done: applied, total: applied_topics)

    # The dashboard lists a course by a short name where one is written, since a
    # full title does not fit beside its progress bar.
    def short_title = I18n.t("progress.enrolled_short.#{code}", default: title)

    # Derived from the syllabus rather than written per course: the first topic
    # not yet finished.
    def next_up
      return I18n.t("progress.next_up_done") if next_key.nil?

      I18n.t("progress.next_up", topic: Syllabus.topic_name(next_key))
    end
  end

  ENTRIES = [
    { code: "AI1101", credits: 3, rating: "4.8", projects: 6, hours: 42, level: :beginner,
      core: true,  certificate: true,  tags: %i[core popular], learners: "1,240" },
    { code: "AI1102", credits: 3, rating: "4.7", projects: 9, hours: 55, level: :beginner,
      core: true,  certificate: true,  tags: %i[core popular], learners: "980" },
    { code: "AI2201", credits: 3, rating: "4.6", projects: 8, hours: 60, level: :intermediate,
      core: true,  certificate: true,  tags: %i[core ml], learners: "612" },
    { code: "AI2105", credits: 2, rating: "4.9", projects: 5, hours: 24, level: :beginner,
      core: false, certificate: true,  tags: %i[popular genai], learners: "1,510" },
    { code: "AI2108", credits: 3, rating: "4.5", projects: 7, hours: 38, level: :intermediate,
      core: false, certificate: false, tags: %i[data], learners: "445" },
    { code: "AI3301", credits: 3, rating: "4.6", projects: 6, hours: 50, level: :advanced,
      core: false, certificate: true,  tags: %i[ml], learners: "288" },
    { code: "AI2210", credits: 2, rating: "4.8", projects: 4, hours: 20, level: :beginner,
      core: false, certificate: false, tags: %i[popular genai], learners: "870" },
    { code: "AI2402", credits: 2, rating: "4.4", projects: 3, hours: 18, level: :beginner,
      core: false, certificate: false, tags: %i[ethics], learners: "520" }
  ].freeze

  class << self
    # The catalog with nobody signed in: taxonomy only, every progress bar at
    # zero. `for` is the one that knows about a learner.
    def all
      ENTRIES.map { |attrs| Course.new(**attrs, learned: 0, applied: 0, next_key: Syllabus.topic_keys.first) }
    end

    def codes = ENTRIES.map { it[:code] }

    # The same list with one learner's counts filled in. LearnerProgress owns the
    # fold, so the whole catalog costs the one query it makes.
    def for(user) = LearnerProgress.new(user).courses

    def find(code, user: nil) = (user ? self.for(user) : all).find { |course| course.code == code }

    # The chip row: every filter with the number of courses behind it.
    def filter_counts
      FILTERS.index_with { |filter| all.count { |course| course.tagged?(filter) } }
    end
  end
end
