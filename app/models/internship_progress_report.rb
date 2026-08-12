# One week of a placement, in the student's words.
#
# Evidence, not assessment: hours are here so a supervisor can see the shape of
# the week, and they are never converted into credit or a grade. Append-only, so
# an acknowledgement can never rewrite what the student wrote.
class InternshipProgressReport < ApplicationRecord
  belongs_to :placement, class_name: "InternshipPlacement", foreign_key: :internship_placement_id,
                         inverse_of: :progress_reports
  belongs_to :acknowledged_by, class_name: "User", optional: true,
                               inverse_of: :acknowledged_internship_progress_reports
  # The supervisor's own pair of columns. Two different people confirm they read
  # the same week for two different reasons, and neither overwrites the other.
  belongs_to :faculty_acknowledged_by, class_name: "User", optional: true,
                                       inverse_of: :faculty_acknowledged_internship_progress_reports

  normalizes :activities, with: ->(value) { value.to_s.strip }
  normalizes :outcomes, with: ->(value) { value.to_s.strip.presence }
  normalizes :blockers, with: ->(value) { value.to_s.strip.presence }

  validates :activities, presence: true, length: { maximum: 5_000 }
  validates :outcomes, length: { maximum: 5_000 }
  validates :blockers, length: { maximum: 5_000 }
  validates :hours, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 168 }, allow_nil: true
  validates :week_starting_on, presence: true
  validates :submitted_at, presence: true
  validate :week_is_a_monday
  validate :week_is_not_in_the_future
  validate :placement_accepts_reports, on: :create
  validate :one_report_per_week

  before_validation :set_submission_defaults, on: :create
  # Append-only: an acknowledgement is the one permitted update, and it is
  # applied through acknowledge! rather than an arbitrary write.
  before_destroy { throw :abort }
  after_create :record_audit_event

  scope :newest_first, -> { order(week_starting_on: :desc, id: :desc) }

  def acknowledged? = acknowledged_at.present?
  def faculty_acknowledged? = faculty_acknowledged_at.present?

  def acknowledge!(actor:)
    raise ActiveRecord::RecordInvalid, self if acknowledged?
    raise ActiveRecord::RecordInvalid, self unless placement.manageable_by?(actor)

    update_columns(acknowledged_by_id: actor.id, acknowledged_at: Time.current, updated_at: Time.current)
    reload
  end

  # The university's acknowledgement of the same week. It records that the
  # assigned supervisor read it and nothing more — no score, no comment, and no
  # edit to the student's text, which stays append-only for them too.
  def faculty_acknowledge!(actor:)
    raise ActiveRecord::RecordInvalid, self if faculty_acknowledged?
    raise ActiveRecord::RecordInvalid, self unless placement.supervised_by?(actor)

    update_columns(faculty_acknowledged_by_id: actor.id, faculty_acknowledged_at: Time.current,
                   updated_at: Time.current)
    reload
  end

  private
    def set_submission_defaults
      self.submitted_at ||= Time.current
      self.week_starting_on ||= Date.current.beginning_of_week
    end

    def week_is_a_monday
      return if week_starting_on.blank?

      errors.add(:week_starting_on, :invalid) unless week_starting_on == week_starting_on.beginning_of_week
    end

    def week_is_not_in_the_future
      return if week_starting_on.blank?

      errors.add(:week_starting_on, :invalid) if week_starting_on > Date.current.beginning_of_week
    end

    def placement_accepts_reports
      return if placement.blank?

      errors.add(:placement, :invalid) unless placement.accepts_reports?
    end

    # The unique index is the real guarantee; this makes the common case a
    # readable error instead of a constraint violation.
    def one_report_per_week
      return if internship_placement_id.blank? || week_starting_on.blank?

      duplicate = self.class.where(internship_placement_id:, week_starting_on:).where.not(id:).exists?
      errors.add(:week_starting_on, :taken) if duplicate
    end

    def record_audit_event
      AuditEvent.create!(user: placement.student, action: "internship_progress_report_submitted",
                         params: { organization: placement.organization.name,
                                   week: week_starting_on.to_s })
    end
end
