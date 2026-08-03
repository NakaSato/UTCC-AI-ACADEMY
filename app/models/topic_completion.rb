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
  validate :topic_belongs_to_course

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
    course = Course.find_by(code: course_code)
    return new(user:, course:, learned_at: at) unless course

    topic = Syllabus.topic(topic_key, course_code)
    return new(user:, course:, topic:, learned_at: at) unless topic&.course_module&.course_id == course.id

    applied = kind.to_sym == :applied
    now = Time.current
    insert_all(
      [ {
        user_id: user.id, course_id: course.id, topic_id: topic.id,
        learned_at: at, applied_at: (at if applied), created_at: now, updated_at: now
      } ],
      unique_by: :index_topic_completions_on_user_id_and_course_id_and_topic_id
    )

    completion = find_by!(user:, course:, topic:)

    completion.update_columns(applied_at: at, updated_at: now) if applied && completion.applied_at.nil?
    LearnerProgress.forget_standings
    completion
  end

  def course_code = course&.code
  def topic_key = topic&.key

  def applied? = applied_at.present?

  # The day this counted towards a streak. Applying a topic later than learning
  # it keeps both days lit, so the grid reflects the work, not the topic.
  def active_days = [ learned_at, applied_at ].compact.map { it.in_time_zone.to_date }.uniq

  private
    def topic_belongs_to_course
      return if course.blank? || topic.blank? || topic.course_module.course_id == course.id

      errors.add(:topic, "must belong to the selected course")
    end
end
