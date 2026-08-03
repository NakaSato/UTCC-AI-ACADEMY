class ApprovalDecision < ApplicationRecord
  OUTCOMES = %w[ approved rejected ].freeze

  belongs_to :approval_request, inverse_of: :decisions
  belongs_to :actor, class_name: "User"

  enum :outcome, OUTCOMES.index_by(&:itself), validate: true

  validates :note, length: { maximum: 500 }, allow_blank: true
  validate :actor_is_approver
  before_update { throw :abort }
  before_destroy { throw :abort }

  private
    def actor_is_approver
      errors.add(:actor, :invalid) unless actor&.admin?
    end
end
