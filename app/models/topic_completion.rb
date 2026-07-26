# One learner finishing one topic. The only record of learning the app keeps —
# every figure on My Learning, Progress and the catalog's progress bars is
# counted off this table.
#
# A topic used to be named by strings — a course code and a "<module>-<position>"
# key — validated against the placeholder taxonomy because nothing else could
# enforce them. Now `courses` and `topics` exist, so those validations are
# foreign keys and the rule that every row names a course and topic that exist is
# true by construction rather than by inspection.
#
# `course_code` and `topic_key` survive as readers. They are what the browser
# posts, what LearnerProgress folds on, and what the URL carries, so the strings
# stay the app's vocabulary even though the columns are gone.
class TopicCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :topic

  # Recorded from the browser, so both halves arrive as params — see
  # LessonsController#complete.
  KINDS = %i[ learned applied ].freeze

  validates :learned_at, presence: true
  validates :topic_id, uniqueness: { scope: %i[ user_id course_id ] }

  scope :applied, -> { where.not(applied_at: nil) }

  # Applying a topic implies having learned it, so a first "applied" report
  # writes both stamps. Idempotent in both directions: re-running the exercise
  # does not move the original timestamp, and re-running the coding task does not
  # write a second row.
  #
  # Still takes the strings. An unknown code or key resolves to nil, which fails
  # `belongs_to` and comes back unpersisted — the same answer the inclusion
  # validations used to give, and what LessonsController checks for.
  def self.record(user:, course_code:, topic_key:, kind:, at: Time.current)
    completion = find_or_initialize_by(user:, course: Course.find_by(code: course_code),
                                       topic: Topic.find_by(key: topic_key))
    completion.learned_at ||= at
    completion.applied_at ||= at if kind.to_sym == :applied
    completion.save
    completion
  end

  def course_code = course&.code
  def topic_key = topic&.key

  def applied? = applied_at.present?

  # The day this counted towards a streak. Applying a topic later than learning
  # it keeps both days lit, so the grid reflects the work, not the topic.
  def active_days = [ learned_at, applied_at ].compact.map { it.in_time_zone.to_date }.uniq
end
