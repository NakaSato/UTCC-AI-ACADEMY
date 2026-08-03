# One thing the proctor saw, reported by the lesson screen and kept. The weight
# is looked up, not stored — what an incident costs is a display convention in
# Proctoring, and re-weighting one must not need a migration.
#
# A "case" on the admin Integrity tab is not a row anywhere: it is a learner's
# unreviewed events, scored on the fly. Closing the case stamps them reviewed.
class ProctorEvent < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :topic

  KINDS = Proctoring::WEIGHTS.keys.map(&:to_s).freeze

  validates :kind, inclusion: { in: KINDS }
  validates :occurred_at, presence: true
  validate :topic_belongs_to_course

  scope :unreviewed, -> { where(reviewed_at: nil) }
  scope :newest_first, -> { order(occurred_at: :desc, id: :desc) }

  def weight = Proctoring::WEIGHTS.fetch(kind.to_sym)

  # The same sentence the lesson sidebar shows for this kind of incident.
  def text = I18n.t("lesson.proctor.events.#{kind}")

  private
    def topic_belongs_to_course
      return if course.blank? || topic.blank? || topic.course_module.course_id == course.id

      errors.add(:topic, "must belong to the selected course")
    end
end
