# Placeholder course data until real models land — see README "Next steps".
# Everything a human reads lives in config/locales; only the numbers and the
# taxonomy live here, so swapping in a Course model means replacing `all`.
module CourseCatalog
  # The order here is the order of the filter chips on the catalog.
  FILTERS = %i[ all core popular ml genai data ethics ].freeze

  Course = Data.define(
    :code, :credits, :rating, :projects, :hours, :level, :core, :certificate,
    :tags, :learners, :done_topics, :all_topics
  ) do
    def title = I18n.t("catalog.courses.#{code}.title")
    def description = I18n.t("catalog.courses.#{code}.desc")
    def instructor = I18n.t("catalog.courses.#{code}.instructor")
    def level_name = I18n.t("levels.#{level}")

    def started? = all_topics.present?
    def percent = started? ? (done_topics * 100.0 / all_topics).round : 0

    # The card's avatar plate. Both locales spell the instructor as an academic
    # title, a space, then the given name ("ผศ.ดร. ชนกานต์", "Asst. Prof.
    # Chanakan"), so the last word is the part worth abbreviating.
    def instructor_initials = instructor.split.last.to_s.first(2)

    def code_line = "#{code} · #{I18n.t('units.credits', count: credits)}"
    def projects_text = I18n.t("units.projects", count: projects)
    def hours_text = I18n.t("units.hours", count: hours)
    def learners_text = I18n.t("units.learners", count: learners)
    def progress_text = I18n.t("units.topics_learned", done: done_topics, total: all_topics)

    def tagged?(filter) = filter == :all || tags.include?(filter)
  end

  ENTRIES = [
    { code: "AI1101", credits: 3, rating: "4.8", projects: 6, hours: 42, level: :beginner,
      core: true,  certificate: true,  tags: %i[core popular], learners: "1,240",
      done_topics: 24, all_topics: 75 },
    { code: "AI1102", credits: 3, rating: "4.7", projects: 9, hours: 55, level: :beginner,
      core: true,  certificate: true,  tags: %i[core popular], learners: "980",
      done_topics: 41, all_topics: 68 },
    { code: "AI2201", credits: 3, rating: "4.6", projects: 8, hours: 60, level: :intermediate,
      core: true,  certificate: true,  tags: %i[core ml], learners: "612",
      done_topics: nil, all_topics: nil },
    { code: "AI2105", credits: 2, rating: "4.9", projects: 5, hours: 24, level: :beginner,
      core: false, certificate: true,  tags: %i[popular genai], learners: "1,510",
      done_topics: 12, all_topics: 30 },
    { code: "AI2108", credits: 3, rating: "4.5", projects: 7, hours: 38, level: :intermediate,
      core: false, certificate: false, tags: %i[data], learners: "445",
      done_topics: nil, all_topics: nil },
    { code: "AI3301", credits: 3, rating: "4.6", projects: 6, hours: 50, level: :advanced,
      core: false, certificate: true,  tags: %i[ml], learners: "288",
      done_topics: nil, all_topics: nil },
    { code: "AI2210", credits: 2, rating: "4.8", projects: 4, hours: 20, level: :beginner,
      core: false, certificate: false, tags: %i[popular genai], learners: "870",
      done_topics: nil, all_topics: nil },
    { code: "AI2402", credits: 2, rating: "4.4", projects: 3, hours: 18, level: :beginner,
      core: false, certificate: false, tags: %i[ethics], learners: "520",
      done_topics: nil, all_topics: nil }
  ].freeze

  class << self
    def all = ENTRIES.map { |attrs| Course.new(**attrs) }

    def find(code) = all.find { |course| course.code == code }

    # The chip row: every filter with the number of courses behind it.
    def filter_counts
      FILTERS.index_with { |filter| all.count { |course| course.tagged?(filter) } }
    end
  end
end
