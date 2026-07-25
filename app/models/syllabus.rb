# The AI1101 module breakdown shown on the course page. Titles and topic names
# come from `course.modules` in the locale files, indexed positionally; the
# status, knowledge-unit count, topic kind and duration live here.
module Syllabus
  Topic = Data.define(:name, :kind, :minutes) do
    def kind_name = I18n.t("course.kind.#{kind}")
    def duration_text = I18n.t("units.minutes", count: minutes)
  end

  Module_ = Data.define(:number, :status, :units, :topics) do
    def title = I18n.t("course.modules")[number - 1][:title]

    # Optional: a module without a `desc:` in the locale file simply renders
    # none, which is how the design ships until an instructor writes one.
    def desc = I18n.t("course.modules")[number - 1][:desc]
    def desc? = desc.present?

    def status_name = I18n.t("course.status.#{status}")
    def done? = status == :done
    def current? = status == :now
    def locked? = status == :locked
    def meta_text = I18n.t("course.module_meta", topics: topics.size, units:)
  end

  # status, knowledge units, [[kind, minutes], …] — one pair per topic, in the
  # same order as the topic names in the locale file.
  ENTRIES = [
    [ :done,   12, [ [ :theory, 8 ], [ :theory, 10 ], [ :exercise, 15 ] ] ],
    [ :now,    18, [ [ :theory, 9 ], [ :theory, 12 ], [ :mix, 14 ], [ :code, 20 ] ] ],
    [ :locked, 22, [ [ :code, 18 ], [ :code, 24 ] ] ],
    [ :locked, 15, [ [ :theory, 11 ], [ :exercise, 16 ] ] ],
    [ :locked, 14, [ [ :theory, 12 ], [ :project, 40 ] ] ],
    [ :locked, 10, [ [ :theory, 10 ], [ :theory, 12 ] ] ]
  ].freeze

  # The module that is open when the course page first loads.
  DEFAULT_OPEN = 2

  # Course-level figures for the four stat tiles and the sidebar table.
  TOPIC_COUNT = 75
  PROJECT_COUNT = 6
  CREDITS = 3
  PERCENT_COMPLETE = 32

  class << self
    def modules
      names = I18n.t("course.modules")

      ENTRIES.each_with_index.map do |(status, units, topics), index|
        Module_.new(
          number: index + 1, status:, units:,
          topics: topics.each_with_index.map { |(kind, minutes), position|
            Topic.new(name: names[index][:topics][position], kind:, minutes:)
          }
        )
      end
    end

    def stats
      [
        { value: TOPIC_COUNT.to_s,                    label: I18n.t("course.stats.topics") },
        { value: PROJECT_COUNT.to_s,                  label: I18n.t("course.stats.projects") },
        { value: I18n.t("course.stats.total_time_value"), label: I18n.t("course.stats.total_time") },
        { value: CREDITS.to_s,                        label: I18n.t("course.stats.credits") }
      ]
    end

    def meta
      [
        [ I18n.t("course.meta.code"), "AI1101" ],
        [ I18n.t("course.meta.prerequisites"), I18n.t("course.meta.prerequisites_value") ],
        [ I18n.t("course.meta.assessment"),    I18n.t("course.meta.assessment_value") ],
        [ I18n.t("course.meta.language"),      I18n.t("course.meta.language_value") ]
      ]
    end
  end
end
