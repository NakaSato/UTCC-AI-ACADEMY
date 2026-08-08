class OrganizationInvitation < ApplicationRecord
  EXPIRATION = 7.days
  ROLES = OrganizationMembership::ROLES - [ "owner" ]

  belongs_to :organization, inverse_of: :invitations
  belongs_to :inviter, class_name: "User", inverse_of: :sent_organization_invitations
  belongs_to :invitee, class_name: "User", inverse_of: :received_organization_invitations

  attr_reader :raw_token

  normalizes :role, with: ->(value) { value.to_s.strip.downcase }

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :role, inclusion: { in: ROLES }
  validate :organization_is_active
  validate :inviter_can_invite
  validate :invitee_is_eligible
  validate :pending_invitation_is_unique

  scope :pending, -> { where(accepted_at: nil, declined_at: nil, revoked_at: nil).where("expires_at > ?", Time.current) }

  before_validation :set_token_and_expiration, on: :create
  before_validation :retire_expired_pending_invitation, on: :create

  def token = raw_token

  def pending? = accepted_at.nil? && declined_at.nil? && revoked_at.nil?

  def active? = pending? && expires_at&.future? && organization.active?

  def acceptable_for?(user)
    active? && invitee_id == user&.id
  end

  def accept!
    with_lock do
      raise ActiveRecord::RecordInvalid, self unless acceptable_for?(invitee)

      transaction do
        membership = organization.memberships.lock.find_or_initialize_by(user_id: invitee_id)
        if membership.persisted? && membership.active? && membership.role != role
          raise ActiveRecord::RecordInvalid, membership
        end

        membership.assign_attributes(role:, status: "active")
        membership.save!
        update!(accepted_at: Time.current)
      end
    end
  end

  def decline!
    with_lock do
      raise ActiveRecord::RecordInvalid, self unless acceptable_for?(invitee)

      update!(declined_at: Time.current)
    end
  end

  private
    def set_token_and_expiration
      return if token_digest.present?

      @raw_token = SecureRandom.urlsafe_base64(48)
      self.token_digest = Digest::SHA256.hexdigest(@raw_token)
      self.expires_at ||= EXPIRATION.from_now
    end

    def retire_expired_pending_invitation
      return if organization.blank? || invitee_id.blank?

      organization.invitations
                 .where(invitee_id:)
                 .where(accepted_at: nil, declined_at: nil, revoked_at: nil)
                 .where("expires_at <= ?", Time.current)
                 .update_all(revoked_at: Time.current)
    end

    def organization_is_active
      errors.add(:organization, :invalid) if organization.present? && !organization.active?
    end

    def inviter_can_invite
      return if inviter.blank? || organization.blank?
      return if inviter.admin?
      return if organization.memberships.active.exists?(user_id: inviter_id, role: "owner")

      errors.add(:inviter, :invalid)
    end

    def invitee_is_eligible
      return if accepted_at.present? || declined_at.present? || revoked_at.present?
      return if invitee.blank?

      errors.add(:invitee, :invalid) if invitee.admin? || inviter_id == invitee_id
      if organization.present? && organization.memberships.active.exists?(user_id: invitee_id)
        errors.add(:invitee, :taken)
      end
    end

    def pending_invitation_is_unique
      return if organization.blank? || invitee_id.blank?

      duplicate = organization.invitations.pending.where(invitee_id:).where.not(id:).exists?
      errors.add(:invitee, :taken) if duplicate
    end
end
