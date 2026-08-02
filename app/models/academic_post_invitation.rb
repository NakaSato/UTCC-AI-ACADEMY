class AcademicPostInvitation < ApplicationRecord
  EXPIRATION = 7.days

  belongs_to :academic_post, inverse_of: :invitations
  belongs_to :inviter, class_name: "User", inverse_of: :sent_academic_post_invitations
  belongs_to :invitee, class_name: "User", inverse_of: :received_academic_post_invitations

  enum :permission, { viewer: "viewer", editor: "editor" }, validate: true

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validate :invitation_targets_an_author
  validate :invitation_is_not_self
  validate :pending_invitation_is_unique

  scope :pending, -> { where(accepted_at: nil, revoked_at: nil).where("expires_at > ?", Time.current) }

  before_validation :set_token_and_expiration, on: :create

  def token = token_digest

  def active?
    accepted_at.nil? && revoked_at.nil? && expires_at&.future?
  end

  def acceptable_for?(user)
    active? && invitee_id == user&.id
  end

  def accept!
    raise ActiveRecord::RecordInvalid, self unless acceptable_for?(invitee)

    transaction do
      membership = academic_post.memberships.find_or_initialize_by(user: invitee)
      unless membership.persisted? && membership.active?
        membership.assign_attributes(permission:, revoked_at: nil)
      end
      membership.save!
      update!(accepted_at: Time.current)
    end
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  private
    def set_token_and_expiration
      self.token_digest ||= Digest::SHA256.hexdigest(SecureRandom.urlsafe_base64(48))
      self.expires_at ||= EXPIRATION.from_now
    end

    def invitation_targets_an_author
      return if invitee.blank? || invitee.student? || invitee.instructor?

      errors.add(:invitee, :invalid)
    end

    def invitation_is_not_self
      errors.add(:invitee, :invalid) if inviter_id.present? && inviter_id == invitee_id
    end

    def pending_invitation_is_unique
      return if academic_post.blank? || invitee_id.blank?

      duplicate = academic_post.invitations.pending.where(invitee_id:).where.not(id:).exists?
      errors.add(:invitee, :taken) if duplicate
    end
end
