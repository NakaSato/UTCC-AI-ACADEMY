class OrganizationMembership < ApplicationRecord
  ROLES = %w[ owner recruiter hiring_manager mentor ].freeze
  STATUSES = %w[ active revoked ].freeze

  belongs_to :organization, inverse_of: :memberships
  belongs_to :user, inverse_of: :organization_memberships

  normalizes :role, with: ->(value) { value.to_s.strip.downcase }
  normalizes :status, with: ->(value) { value.to_s.strip.downcase }

  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :organization_id }
  validate :member_cannot_be_an_admin

  scope :active, -> { where(status: "active") }

  def active? = status == "active"

  def owner? = role == "owner"

  def revoke!
    raise ActiveRecord::RecordInvalid, self if owner? && active?

    update!(status: "revoked")
  end

  private
    def member_cannot_be_an_admin
      errors.add(:user, :invalid) if user&.admin?
    end
end
