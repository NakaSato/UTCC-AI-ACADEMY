# A student's deliverable for one milestone, append-only by construction: a
# revision is a new row with the next version, never an edit, so company review
# can never rewrite the student's original evidence (SPEC-0040 invariant 8).
class BusinessCaseSubmission < ApplicationRecord
  belongs_to :business_case, inverse_of: :submissions
  belongs_to :milestone, class_name: "BusinessCaseMilestone", foreign_key: :business_case_milestone_id,
                         inverse_of: :submissions
  belongs_to :author, class_name: "User", inverse_of: :business_case_submissions

  normalizes :body, with: ->(value) { value.to_s.strip }

  validates :body, presence: true, length: { maximum: 10_000 }
  validates :submitted_at, presence: true
  validates :version, numericality: { greater_than_or_equal_to: 1, only_integer: true }
  validate :milestone_belongs_to_case
  validate :author_is_an_active_student_participant
  validate :case_is_open_for_submissions, on: :create

  before_validation :set_submission_time_and_version, on: :create
  before_update { throw :abort }
  before_destroy { throw :abort }
  after_create :record_audit_event

  scope :newest_first, -> { order(submitted_at: :desc, id: :desc) }

  private
    def set_submission_time_and_version
      self.submitted_at ||= Time.current
      return if business_case_milestone_id.blank? || author_id.blank?

      self.version = self.class.where(business_case_milestone_id:, author_id:).maximum(:version).to_i + 1
    end

    def milestone_belongs_to_case
      return if milestone.blank? || business_case.blank?

      errors.add(:milestone, :invalid) unless milestone.business_case_id == business_case_id
    end

    # Re-derived from the database at write time so a revocation that happened
    # after this object was loaded still fails closed.
    def author_is_an_active_student_participant
      return if author.blank? || business_case.blank?
      return if BusinessCaseParticipant.active.where(business_case_id:, user_id: author_id, role: "student").exists?

      errors.add(:author, :invalid)
    end

    def case_is_open_for_submissions
      errors.add(:business_case, :invalid) if business_case.present? && !business_case.open_for_submissions?
    end

    def record_audit_event
      AuditEvent.create!(user: author, action: "business_case_submission_created",
                         params: { organization: business_case.organization.name,
                                   business_case: business_case.title,
                                   milestone: milestone.title, version: })
    end
end
