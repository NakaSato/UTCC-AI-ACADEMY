# The catalog, read off the `courses` table. Everything a human reads still lives
# in config/locales, looked up by course code — the table carries identity,
# taxonomy and numbers only, which is why `Course` below did not change when the
# rows landed and why no view did either.
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

  class << self
    # The catalog with nobody signed in: taxonomy only, every progress bar at
    # zero. `for` is the one that knows about a learner.
    def all
      first_key = Syllabus.topic_keys.first

      records.map { Course.new(**attributes_for(it), learned: 0, applied: 0, next_key: first_key) }
    end

    # The rows behind the catalog, in catalog order. One query; `all` and `for`
    # both fold off it rather than asking per course.
    def records = ::Course.in_catalog_order.to_a

    def codes = records.map(&:code)

    # A row's columns, named the way the read model wants them. The one
    # conversion is `tags`, which comes back from the json column as strings.
    def attributes_for(record)
      { code: record.code, credits: record.credits, rating: record.rating,
        projects: record.projects, hours: record.hours, level: record.level.to_sym,
        core: record.core, certificate: record.certificate,
        tags: record.tags, learners: record.learners }
    end

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
