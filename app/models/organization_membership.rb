class OrganizationMembership < ApplicationRecord
  # `company_reviewer` is the company-side counterpart to the hiring roles: it
  # carries the same recruitment authoring and review reach, and additionally
  # runs business cases, which `owner` alone could do — and an organization has
  # only one active owner, so case work had nowhere else to live.
  ROLES = %w[ owner recruiter hiring_manager mentor company_reviewer ].freeze
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

  def company_reviewer? = role == "company_reviewer"

  def revoke!
    raise ActiveRecord::RecordInvalid, self if owner? && active?

    update!(status: "revoked")
  end

  private
    def member_cannot_be_an_admin
      errors.add(:user, :invalid) if user&.admin?
    end
end
