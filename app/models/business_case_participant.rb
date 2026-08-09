# The record that actually grants case access. Students only arrive here
# through an accepted invitation; mentors only through an explicit owner
# assignment — an instructor account alone never appears in this table
# (SPEC-0040 invariant 6). Revocation ends access but keeps the row, so the
# participant's submissions and comments stay attributable.
class BusinessCaseParticipant < ApplicationRecord
  ROLES = %w[ student mentor ].freeze

  belongs_to :business_case, inverse_of: :participants
  belongs_to :user, inverse_of: :business_case_participations
  belongs_to :assigned_by, class_name: "User", optional: true, inverse_of: :assigned_business_case_participants

  normalizes :role, with: ->(value) { value.to_s.strip.downcase }

  validates :role, inclusion: { in: ROLES }
  validate :user_matches_role
  validate :mentor_is_assigned_by_an_owner
  validate :single_active_assignment
  validate :business_case_is_not_closed, on: :create

  scope :active, -> { where(revoked_at: nil) }

  def active? = revoked_at.nil?

  def student? = role == "student"
  def mentor? = role == "mentor"

  def revoke!
    update!(revoked_at: Time.current)
  end

  private
    # Revocation is deliberately exempt: an account role that changed after the
    # grant must never be able to keep someone inside a confidential case.
    def user_matches_role
      return if user.blank? || revoked_at.present?
      return if student? && user.student?
      return if mentor? && user.instructor?

      errors.add(:user, :invalid)
    end

    def mentor_is_assigned_by_an_owner
      return unless mentor?
      return if revoked_at.present?

      if assigned_by.blank? || (business_case.present? && !business_case.manageable_by?(assigned_by))
        errors.add(:assigned_by, :invalid)
      end
    end

    def business_case_is_not_closed
      errors.add(:business_case, :invalid) if business_case&.closed?
    end

    def single_active_assignment
      return if revoked_at.present? || business_case.blank?

      duplicate = business_case.participants.active.where(user_id:).where.not(id:).exists?
      errors.add(:user, :taken) if duplicate
    end
end
