class AcademicPostMembership < ApplicationRecord
  belongs_to :academic_post, inverse_of: :memberships
  belongs_to :user, inverse_of: :academic_post_memberships

  enum :permission, { viewer: "viewer", editor: "editor" }, validate: true

  validates :user_id, uniqueness: { scope: :academic_post_id }
  validate :user_must_be_an_author

  scope :active, -> { where(revoked_at: nil) }

  def active? = revoked_at.nil?

  def editable? = active? && editor?

  def revoke!
    update!(revoked_at: Time.current)
  end

  private
    def user_must_be_an_author
      return if user&.student? || user&.instructor?

      errors.add(:user, :invalid)
    end
end
