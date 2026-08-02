class AcademicPost < ApplicationRecord
  belongs_to :owner, class_name: "User", inverse_of: :academic_posts
  has_many :memberships, class_name: "AcademicPostMembership", dependent: :destroy,
                         inverse_of: :academic_post
  has_many :collaborators, through: :memberships, source: :user
  has_many :invitations, class_name: "AcademicPostInvitation", dependent: :destroy,
                         inverse_of: :academic_post
  has_many :revisions, class_name: "AcademicPostRevision", dependent: :destroy,
                       inverse_of: :academic_post
  has_many_attached :pictures

  enum :status, { draft: "draft", review: "review", published: "published" },
       default: :draft, validate: true

  validates :title, length: { maximum: 200 }
  validates :body, length: { maximum: 100_000 }
  validate :owner_must_be_an_author
  before_validation :sanitize_body

  scope :owned_by, ->(user) { where(owner: user) }

  def ready_for_review?
    title.present? && body.present?
  end

  def save_draft!(author:, expected_lock_version:, attributes:)
    transaction do
      self.lock_version = expected_lock_version.to_i
      assign_attributes(attributes)
      save!
      revisions.create!(author:, version: lock_version, title:, body:)
    end
  end

  def latest_revision
    revisions.order(version: :desc).first
  end

  def owned_by?(user) = owner_id == user&.id

  def accessible_to?(user)
    owned_by?(user) || memberships.active.exists?(user_id: user&.id)
  end

  def editable_by?(user)
    owned_by?(user) || memberships.active.where(user_id: user&.id, permission: "editor").exists?
  end

  private
    def owner_must_be_an_author
      return if owner&.student? || owner&.instructor?

      errors.add(:owner, :invalid)
    end

    def sanitize_body
      self.body = AcademicPostContentSanitizer.sanitize(body)
    end
end
