# An organization-owned collaboration around one real company challenge.
# Access is never inferred from a URL or an organization role alone: owners
# manage through an active owner membership, students through an accepted
# invitation, mentors through an explicit assignment — and nobody else, admins
# included, until a reason-gated support surface exists (SPEC-0040).
class BusinessCase < ApplicationRecord
  STATUSES = %w[ draft published closed ].freeze
  TRANSITIONS = {
    "draft" => %w[ published closed ],
    "published" => %w[ closed ],
    "closed" => []
  }.freeze

  belongs_to :organization, inverse_of: :business_cases
  belongs_to :owner, class_name: "User", inverse_of: :owned_business_cases
  has_many :invitations, class_name: "BusinessCaseInvitation", dependent: :restrict_with_exception,
                         inverse_of: :business_case
  has_many :participants, class_name: "BusinessCaseParticipant", dependent: :restrict_with_exception,
                          inverse_of: :business_case
  has_many :milestones, class_name: "BusinessCaseMilestone", dependent: :restrict_with_exception,
                        inverse_of: :business_case
  has_many :submissions, class_name: "BusinessCaseSubmission", dependent: :restrict_with_exception,
                         inverse_of: :business_case
  has_many :comments, class_name: "BusinessCaseComment", dependent: :restrict_with_exception,
                      inverse_of: :business_case

  attr_accessor :status_transition_context

  normalizes :title, with: ->(value) { value.to_s.strip }
  normalizes :status, with: ->(value) { value.to_s.strip.downcase }

  validates :title, presence: true, length: { maximum: 160 }
  validates :brief, length: { maximum: 10_000 }
  validates :requirements, length: { maximum: 10_000 }
  validates :status, inclusion: { in: STATUSES }
  validate :organization_is_active, on: :create
  validate :owner_holds_active_ownership, on: :create
  validate :initial_status_is_draft, on: :create
  validate :status_change_requires_transition_context, on: :update
  validate :closed_case_is_immutable, on: :update

  before_update :forbid_organization_change

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def draft? = status == "draft"
  def published? = status == "published"
  def closed? = status == "closed"

  def editable? = !closed?
  def open_for_invitations? = published? && organization.active?
  def open_for_submissions? = published? && organization.active?
  def open_for_comments? = published? && organization.active?

  # Re-derived from the database on every call rather than trusting a loaded
  # association, so a membership revoked mid-session fails closed.
  def manageable_by?(user)
    return false unless user && Organization.active.where(id: organization_id).exists?

    OrganizationMembership.where(organization_id:, user_id: user.id, status: "active", role: "owner").exists?
  end

  def accessible_to?(user)
    return false if user.blank?

    manageable_by?(user) || participants.active.exists?(user_id: user.id)
  end

  def transition_to!(target, actor:, lock_version: nil)
    target = target.to_s.strip.downcase
    updated_case = self.class.transaction do
      locked_case = self.class.lock.find(id)
      raise ActiveRecord::StaleObjectError.new(locked_case, "update") if lock_version.present? &&
        locked_case.lock_version.to_i != lock_version.to_i
      raise ActiveRecord::RecordInvalid, locked_case unless locked_case.manageable_by?(actor) &&
                                                            TRANSITIONS.fetch(locked_case.status, []).include?(target)

      locked_case.status_transition_context = true
      stamps = { status: target }
      stamps[:published_at] = Time.current if target == "published"
      stamps[:closed_at] = Time.current if target == "closed"
      locked_case.update!(**stamps)
      locked_case
    end
    assign_attributes(updated_case.attributes)
    self
  end

  private
    def organization_is_active
      errors.add(:organization, :invalid) if organization.present? && !organization.active?
    end

    def owner_holds_active_ownership
      return if owner.blank? || organization.blank?
      return if organization.memberships.active.exists?(user_id: owner_id, role: "owner")

      errors.add(:owner, :invalid)
    end

    def initial_status_is_draft
      errors.add(:status, :invalid) unless status == "draft"
    end

    def status_change_requires_transition_context
      return unless will_save_change_to_status?
      return if status_transition_context

      errors.add(:status, :invalid)
    end

    def closed_case_is_immutable
      errors.add(:base, :invalid) if status_was == "closed"
    end

    def forbid_organization_change
      throw :abort if organization_id_changed?
    end
end
