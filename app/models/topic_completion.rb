# One learner finishing one topic. The only record of learning the app keeps —
# every figure on My Learning, Progress and the catalog's progress bars is
# counted off this table.
#
# There are no Course or Topic tables yet, so a topic is named by the placeholder
# taxonomy: a course code from CourseCatalog and a "<module>-<position>" key from
# Syllabus. Validating against both is what keeps the strings honest until real
# models land — a completion for a course that does not exist cannot be written.
class TopicCompletion < ApplicationRecord
  belongs_to :user

  # Recorded from the browser, so both halves arrive as params — see
  # LessonsController#complete.
  KINDS = %i[ learned applied ].freeze

  validates :course_code, presence: true, inclusion: { in: ->(_) { CourseCatalog.codes } }
  validates :topic_key, presence: true, inclusion: { in: ->(_) { Syllabus.topic_keys } }
  validates :learned_at, presence: true
  validates :topic_key, uniqueness: { scope: %i[ user_id course_code ] }

  scope :applied, -> { where.not(applied_at: nil) }

  # Applying a topic implies having learned it, so a first "applied" report
  # writes both stamps. Idempotent in both directions: re-running the exercise
  # does not move the original timestamp, and re-running the coding task does not
  # write a second row.
  def self.record(user:, course_code:, topic_key:, kind:, at: Time.current)
    completion = find_or_initialize_by(user:, course_code:, topic_key:)
    completion.learned_at ||= at
    completion.applied_at ||= at if kind.to_sym == :applied
    completion.save
    completion
  end

  def applied? = applied_at.present?

  # The day this counted towards a streak. Applying a topic later than learning
  # it keeps both days lit, so the grid reflects the work, not the topic.
  def active_days = [ learned_at, applied_at ].compact.map { it.in_time_zone.to_date }.uniq
end
