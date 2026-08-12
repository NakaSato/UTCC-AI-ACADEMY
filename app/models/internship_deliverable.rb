# The work a student produced during a placement, and the first file in this
# repository that one person uploads for another person to read.
#
# The safety envelope is the one SPEC-0029 already enforces on a candidate's
# portfolio, because a deliverable is the same kind of thing: an allowlist of
# content types and a ten-megabyte ceiling. Nothing is scanned — nothing in this
# application is — so the second half matters more than the first: a deliverable
# is only ever served as a download, by a controller that rechecks who is
# asking, and never rendered inline for a reader's browser to interpret.
#
# The student owns it. They upload it, they delete it, and nothing expires it on
# a timer — ADR-0041 decision 5.
class InternshipDeliverable < ApplicationRecord
  # The portfolio allowlist, which is already this project's answer to "what may
  # a student hand over as work", plus plain text for a README.
  CONTENT_TYPES = (CandidateProfile::PORTFOLIO_CONTENT_TYPES + %w[ text/plain ]).freeze
  MAX_BYTES = CandidateProfile::MAX_ATTACHMENT_BYTES

  belongs_to :placement, class_name: "InternshipPlacement", foreign_key: :internship_placement_id,
                         inverse_of: :deliverables
  belongs_to :author, class_name: "User", inverse_of: :internship_deliverables

  has_one_attached :file

  normalizes :title, with: ->(value) { value.to_s.strip }

  validates :title, presence: true, length: { maximum: 160 }
  validate :file_is_attached_and_safe
  validate :author_is_the_placed_student, on: :create
  validate :placement_accepts_deliverables, on: :create

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  after_create :record_audit_event

  # The placed student always. The company that hosted it while the internship
  # is open, and no longer once it has ended — decision 5's access rule.
  #
  # Deliberately not the faculty supervisor: their assignment grants the
  # placement and its weekly reports (decision 7), and extending it to the
  # student's files was offered and not taken.
  def readable_by?(user)
    return false if user.blank?
    return true if author_id == user.id

    placement.open? && placement.manageable_by?(user)
  end

  # The student owns their work, so the student removes it — and nobody else,
  # including the company that read it.
  def deletable_by?(user) = user.present? && author_id == user.id

  def destroy_for!(actor:)
    raise ActiveRecord::RecordInvalid, self unless deletable_by?(actor)

    filename = file.filename.to_s
    destroy!
    AuditEvent.record("internship_deliverable_removed", organization: placement.organization.name,
                      filename:)
    self
  end

  private
    def file_is_attached_and_safe
      return errors.add(:file, :blank) unless file.attached?

      errors.add(:file, :invalid) unless CONTENT_TYPES.include?(file.content_type)
      errors.add(:file, :too_large) if file.byte_size > MAX_BYTES
    end

    def author_is_the_placed_student
      errors.add(:author, :invalid) unless placement && author_id == placement.student_id
    end

    def placement_accepts_deliverables
      errors.add(:base, :invalid) unless placement&.open?
    end

    # The filename, never the file: an audit row records that work was handed
    # over, not what was in it.
    def record_audit_event
      AuditEvent.record("internship_deliverable_added", organization: placement.organization.name,
                        filename: file.filename.to_s)
    end
end
