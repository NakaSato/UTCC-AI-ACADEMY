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
  SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  validates :slug, presence: true, uniqueness: { case_sensitive: false },
                   format: { with: SLUG_FORMAT },
                   length: { maximum: 80 }
  validates :status, inclusion: { in: STATUSES }
  # No reserved-name list: the profile lives under /company/:slug, so a company
  # called "admin" is reachable at /company/admin and shadows nothing. A list
  # here would have to name every top-level route and be re-checked whenever one
  # was added — a standing tax for a collision the prefix already prevents.

  scope :active, -> { where(status: "active") }
  scope :accepting_internship_requests, -> { active.where(accepts_internship_requests: true) }

  # The slug is the organization's name in every URL it appears in — the vanity
  # profile at /northstar, and the workspace routes nested under it. Overriding
  # `to_param` is what keeps those two in step: a path helper handed the record
  # writes the name, never the row id.
  def to_param = slug

  # ...and its other half. Every organization id in a route is a slug now, so
  # the lookup lives in one place rather than in seventeen controllers, and
  # `Organization.find` in a controller is a mistake this makes visible.
  def self.from_param!(param) = find_by!(slug: param.to_s)

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
