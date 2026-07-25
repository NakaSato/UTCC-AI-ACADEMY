# The instructor view of a section: cohort figures, the topics students fail
# most often on first attempt, and the roster.
module InstructorReport
  STAT_VALUES = [ "38%", "82%", "6", "7.4" ].freeze

  # Percent failing on first attempt, in the same order as
  # `instructor.hard_topics` in the locale files.
  HARD_TOPIC_PERCENTS = [ 61, 54, 43, 29, 12 ].freeze

  # Above this share the bar reads as a problem rather than a warning.
  ALARM_THRESHOLD = 50
  WARN_THRESHOLD = 40

  # A student is on track at 50%+, behind under 25%.
  ON_TRACK = 50
  BEHIND = 25

  Student = Data.define(:id, :name, :percent, :projects, :projects_total, :seen) do
    def on_track? = percent >= ON_TRACK
    def behind? = percent < BEHIND
    def projects_text = "#{projects} / #{projects_total}"

    def seen_text
      case seen
      in 0 then I18n.t("instructor.seen.today")
      in 1 then I18n.t("instructor.seen.yesterday")
      else      I18n.t("instructor.seen.days_ago", count: seen)
      end
    end
  end

  # id, percent, projects submitted, days since last seen
  ROSTER = [
    [ "6512400118", 74, 6,  0 ],
    [ "6512400226", 68, 5,  0 ],
    [ "6512400341", 59, 5,  1 ],
    [ "6512400407", 32, 4,  0 ],
    [ "6512400512", 28, 3,  3 ],
    [ "6512400633", 21, 2,  8 ],
    [ "6512400744",  9, 1, 12 ]
  ].freeze

  PROJECTS_TOTAL = 6

  class << self
    def stats
      I18n.t("instructor.stats").each_with_index.map do |copy, index|
        copy.merge(value: STAT_VALUES[index])
      end
    end

    def hard_topics
      names = I18n.t("instructor.hard_topics")

      HARD_TOPIC_PERCENTS.each_with_index.map do |percent, index|
        { name: names[index], percent:, severity: severity_for(percent) }
      end
    end

    def roster
      names = I18n.t("instructor.roster")

      ROSTER.each_with_index.map do |(id, percent, projects, seen), index|
        Student.new(id:, name: names[index], percent:, projects:,
                    projects_total: PROJECTS_TOTAL, seen:)
      end
    end

    private
      def severity_for(percent)
        return :alarm if percent >= ALARM_THRESHOLD
        return :warn  if percent >= WARN_THRESHOLD

        :notice
      end
  end
end
