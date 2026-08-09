class ProposalRequest < ApplicationRecord
  CATEGORIES = %w[ feature curriculum community platform ].freeze
  STATUSES = %w[ submitted in_review planned declined ].freeze

  belongs_to :user, inverse_of: :proposal_requests

  normalizes :title, :category, :problem, :idea, :impact, with: ->(value) { value.to_s.strip.presence }

  validates :title, presence: true, length: { maximum: 160 }
  validates :category, inclusion: { in: CATEGORIES }
  validates :problem, presence: true, length: { maximum: 2_000 }
  validates :idea, presence: true, length: { maximum: 4_000 }
  validates :impact, presence: true, length: { maximum: 1_000 }
  validates :status, inclusion: { in: STATUSES }
  validate :user_must_be_a_contributor

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def reference = "PR-%04d" % id

  private
    def user_must_be_a_contributor
      errors.add(:user, :invalid) unless user&.student? || user&.instructor?
    end
end
