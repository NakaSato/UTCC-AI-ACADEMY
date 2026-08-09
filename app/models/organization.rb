class Organization < ApplicationRecord
  STATUSES = %w[ active suspended ].freeze

  belongs_to :creator, class_name: "User", inverse_of: :created_organizations
  has_many :memberships, class_name: "OrganizationMembership", dependent: :restrict_with_exception,
                         inverse_of: :organization
  has_many :invitations, class_name: "OrganizationInvitation", dependent: :restrict_with_exception,
                         inverse_of: :organization
  has_many :job_posts, class_name: "Recruitment::JobPost", dependent: :restrict_with_exception,
                       inverse_of: :organization
  has_many :internship_programs, class_name: "Recruitment::InternshipProgram", dependent: :restrict_with_exception,
                                 inverse_of: :organization
  has_many :business_cases, dependent: :restrict_with_exception, inverse_of: :organization
  has_many :internship_requests, dependent: :restrict_with_exception, inverse_of: :organization
  has_many :internship_placements, dependent: :restrict_with_exception, inverse_of: :organization
  has_many :members, through: :memberships, source: :user

  normalizes :name, with: ->(value) { value.to_s.strip }
  normalizes :slug, with: ->(value) { value.to_s.strip.downcase }

  before_validation :derive_slug, on: :create

  validates :name, presence: true, length: { maximum: 160 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ },
                   length: { maximum: 80 }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :accepting_internship_requests, -> { active.where(accepts_internship_requests: true) }

  def active? = status == "active"

  def member?(user)
    memberships.active.exists?(user_id: user&.id)
  end

  def visible_to?(user)
    user&.admin? || member?(user)
  end

  private
    def derive_slug
      self.slug = name.to_s.parameterize if slug.blank?
    end
end
