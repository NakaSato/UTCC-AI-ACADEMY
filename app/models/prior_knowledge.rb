# A learner's course-scoped, reversible assertion that a topic is already known.
# It is intentionally not a TopicCompletion: it contributes to the knowledge
# map and course progress, but never to XP, activity, awards, applied work,
# reports, certificates, or the lesson unlock rule.
class PriorKnowledge < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :topic

  validates :marked_at, presence: true
  validates :topic_id, uniqueness: { scope: %i[ user_id course_id ] }
  validate :topic_belongs_to_course

  scope :for_course, ->(course) { where(course:) }

  def self.mark(user:, course:, topic:, at: Time.current)
    find_or_create_by!(user:, course:, topic:) do |record|
      record.marked_at = at
    end
  end

  def course_code = course&.code
  def topic_key = topic&.key

  private
    def topic_belongs_to_course
      return if course.blank? || topic.blank? || topic.course_module.course_id == course.id

      errors.add(:topic, "must belong to the selected course")
    end
end
