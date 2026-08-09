# A single-use, expiring grant of one case to one student. The token exists in
# memory only at creation; the row keeps a SHA-256 digest, so a database read
# can never reproduce a working invitation URL (same bargain as
# OrganizationInvitation). Acceptance — not the invitation — creates access.
class BusinessCaseInvitation < ApplicationRecord
  EXPIRATION = 7.days

  belongs_to :business_case, inverse_of: :invitations
  belongs_to :inviter, class_name: "User", inverse_of: :sent_business_case_invitations
  belongs_to :invitee, class_name: "User", inverse_of: :received_business_case_invitations

  attr_reader :raw_token

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validate :business_case_is_open, on: :create
  validate :inviter_can_invite
  validate :invitee_is_eligible
  validate :pending_invitation_is_unique

  scope :pending, -> { where(accepted_at: nil, declined_at: nil, revoked_at: nil).where("expires_at > ?", Time.current) }

  before_validation :set_token_and_expiration, on: :create
  before_validation :retire_expired_pending_invitation, on: :create

  def token = raw_token

  def pending? = accepted_at.nil? && declined_at.nil? && revoked_at.nil?

  def active? = pending? && expires_at&.future? && business_case.open_for_invitations?

  def acceptable_for?(user)
    active? && invitee_id == user&.id
  end

  def accept!
    with_lock do
      raise ActiveRecord::RecordInvalid, self unless acceptable_for?(invitee)

      transaction do
        participant = business_case.participants.lock.find_or_initialize_by(user_id: invitee_id)
        raise ActiveRecord::RecordInvalid, participant if participant.persisted? && participant.active?

        participant.assign_attributes(role: "student", revoked_at: nil, assigned_by: nil)
        participant.save!
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
      return if business_case.blank? || invitee_id.blank?

      business_case.invitations
                   .where(invitee_id:)
                   .where(accepted_at: nil, declined_at: nil, revoked_at: nil)
                   .where("expires_at <= ?", Time.current)
                   .update_all(revoked_at: Time.current)
    end

    def business_case_is_open
      errors.add(:business_case, :invalid) if business_case.present? && !business_case.open_for_invitations?
    end

    def inviter_can_invite
      return if inviter.blank? || business_case.blank?
      return if business_case.manageable_by?(inviter)

      errors.add(:inviter, :invalid)
    end

    def invitee_is_eligible
      return if accepted_at.present? || declined_at.present? || revoked_at.present?
      return if invitee.blank?

      errors.add(:invitee, :invalid) unless invitee.student?
      errors.add(:invitee, :invalid) if inviter_id == invitee_id
      if business_case.present? && business_case.participants.active.exists?(user_id: invitee_id)
        errors.add(:invitee, :taken)
      end
    end

    def pending_invitation_is_unique
      return if business_case.blank? || invitee_id.blank?

      duplicate = business_case.invitations.pending.where(invitee_id:).where.not(id:).exists?
      errors.add(:invitee, :taken) if duplicate
    end
end
