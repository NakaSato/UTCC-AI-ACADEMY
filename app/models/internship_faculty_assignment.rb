# The university's side of an internship: one staff member, assigned to one
# placement, who may read it and acknowledge the weeks as they come.
#
# The assignment is the consent. ADR-0041 rejected reading faculty authority off
# the `instructor` role — teaching a course is not agreement to read a named
# student's internship and a company's decision — and rejected a second identity
# store. So authority lives here, exactly as company reach lives in an
# OrganizationMembership: one User, one deliberate, audited grant.
#
# It carries no gate. A supervisor does not approve a request, advance a
# placement, or complete one; an absent supervisor never strands a student
# mid-internship. See ADR-0041 decision 2, answered 2026-08-12.
class InternshipFacultyAssignment < ApplicationRecord
  STATUSES = %w[ active revoked ].freeze

  belongs_to :placement, class_name: "InternshipPlacement", foreign_key: :internship_placement_id,
                         inverse_of: :faculty_assignments
  belongs_to :faculty, class_name: "User", inverse_of: :internship_faculty_assignments
  belongs_to :assigned_by, class_name: "User", inverse_of: :assigned_internship_faculty_assignments

  validates :status, inclusion: { in: STATUSES }
  validate :faculty_is_staff, on: :create
  validate :placement_has_no_other_supervisor, on: :create
  validate :assigned_by_is_an_administrator, on: :create

  scope :active, -> { where(status: "active") }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  after_create :record_assignment_audit_event

  def active? = status == "active"
  def revoked? = status == "revoked"

  # An administrator grants it and an administrator takes it away, so there is
  # one place to look for who could read a student's internship.
  def revoke!(actor:)
    raise ActiveRecord::RecordInvalid, self unless revocable_by?(actor)
    raise ActiveRecord::RecordInvalid, self if revoked?

    update!(status: "revoked", revoked_at: Time.current)
    AuditEvent.record("internship_faculty_assignment_revoked", placement: internship_placement_id.to_s,
                      faculty: faculty.identifier)
    self
  end

  def revocable_by?(user) = user.present? && user.admin?

  private
    # Staff, not any account: this is the university in the loop. Which staff is
    # the administrator's judgement, not a rule the platform can compute.
    def faculty_is_staff
      errors.add(:faculty, :invalid) unless faculty&.staff?
    end

    def placement_has_no_other_supervisor
      return if internship_placement_id.blank?

      existing = self.class.active.where(internship_placement_id:)
      errors.add(:base, :taken) if existing.exists?
    end

    def assigned_by_is_an_administrator
      errors.add(:assigned_by, :invalid) unless assigned_by&.admin?
    end

    # The identifier, never the student's name or a word of their report: an
    # audit row records who was given reach, not what they then read.
    def record_assignment_audit_event
      AuditEvent.record("internship_faculty_assignment_created", placement: internship_placement_id.to_s,
                        faculty: faculty.identifier)
    end
end
