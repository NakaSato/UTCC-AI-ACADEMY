# What a student may do with an AI assistant in one lesson, and what they must
# say about it.
#
# An academy that proctors its lessons and says nothing about AI use is asking
# students to guess where the line is, then recording them crossing it. This is
# the line, written down per lesson and shown on the lesson itself.
#
# A sibling of [[LessonIntegritySetting]] rather than a column on it: that
# setting decides whether the proctor log is *shown*, this decides what is
# *allowed*, and neither implies the other. A teacher may perfectly well allow an
# assistant and still hide the log, or forbid it and show it.
#
# The three uses are a whitelist this model owns, and they name what a student
# would *do* rather than a product they would open. Brand names date, and a rule
# written against one is silent about the next one.
class LessonAiPolicy < ApplicationRecord
  belongs_to :course

  USES = %w[ explain draft review ].freeze
  STANCES = %w[ allowed disclose forbidden ].freeze

  # The default is "disclose", not "allowed": the honest default for a course
  # that has not thought about it yet is that using an assistant is fine and
  # saying so is expected. A silent default of `allowed` would make the panel
  # decoration; a silent default of `forbidden` would make every lesson a trap.
  DEFAULT_STANCE = "disclose".freeze

  validates :topic_key, presence: true, uniqueness: { scope: [ :course_id, :use_key ] }
  validates :use_key, inclusion: { in: USES }
  validates :stance, inclusion: { in: STANCES }
  validates :lock_version, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def use_name = I18n.t("lesson.ai.uses.#{use_key}")
  def stance_name = I18n.t("lesson.ai.stances.#{stance}")
  def forbidden? = stance == "forbidden"

  class << self
    # Every use for one lesson, in the order USES declares, whether or not a row
    # exists — the same shape `LessonIntegritySetting.rows_for` takes, and for
    # the same reason: the screen renders a fixed set and a missing row is a
    # default rather than a gap.
    def rows_for(course:, topic_key:)
      stored = where(course:, topic_key:).index_by(&:use_key)

      USES.map do |use_key|
        stored[use_key] || new(course:, topic_key:, use_key:, stance: DEFAULT_STANCE, lock_version: 0)
      end
    end

    # Every lesson's rows in one query, for the tab that draws three stances for
    # every topic in the syllabus. `rows_for` per lesson would be one query per
    # lesson, which is the shape this codebase spends its comments avoiding.
    def rows_for_all(course:, topic_keys:)
      stored = where(course:, topic_key: topic_keys).group_by(&:topic_key)

      topic_keys.index_with do |topic_key|
        by_use = stored.fetch(topic_key, []).index_by(&:use_key)
        USES.map do |use_key|
          by_use[use_key] || new(course:, topic_key:, use_key:, stance: DEFAULT_STANCE, lock_version: 0)
        end
      end
    end

    def stance_for(course:, topic_key:, use_key:)
      find_by(course:, topic_key:, use_key:)&.stance || DEFAULT_STANCE
    end

    def update!(course:, topic_key:, use_key:, stance:, expected_lock_version:)
      policy = find_or_initialize_by(course:, topic_key:, use_key:)
      expected = Integer(expected_lock_version, exception: false)
      raise ActiveRecord::StaleObjectError, policy if expected.nil? || expected != policy.lock_version

      policy.update!(stance:)
      policy
    end
  end
end
