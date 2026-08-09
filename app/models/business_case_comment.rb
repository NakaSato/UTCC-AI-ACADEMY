# Mentoring and review conversation on a case: immutable once posted, readable
# by every participant, and never a grade or a recruitment decision.
class BusinessCaseComment < ApplicationRecord
  belongs_to :business_case, inverse_of: :comments
  belongs_to :author, class_name: "User", inverse_of: :business_case_comments

  normalizes :body, with: ->(value) { value.to_s.strip }

  validates :body, presence: true, length: { maximum: 4_000 }
  validates :posted_at, presence: true
  validate :author_can_participate
  validate :case_is_open_for_comments, on: :create

  before_validation :set_posted_time, on: :create
  before_update { throw :abort }
  before_destroy { throw :abort }
  after_create :record_audit_event

  scope :oldest_first, -> { order(:posted_at, :id) }

  private
    def set_posted_time
      self.posted_at ||= Time.current
    end

    def author_can_participate
      return if author.blank? || business_case.blank?
      return if business_case.participants.active.exists?(user_id: author_id)
      return if business_case.manageable_by?(author)

      errors.add(:author, :invalid)
    end

    def case_is_open_for_comments
      errors.add(:business_case, :invalid) if business_case.present? && !business_case.open_for_comments?
    end

    def record_audit_event
      AuditEvent.create!(user: author, action: "business_case_comment_created",
                         params: { organization: business_case.organization.name,
                                   business_case: business_case.title })
    end
end
