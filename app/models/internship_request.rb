# A student asking a company for an internship it never advertised.
#
# Deliberately position-less: there is no association to a
# Recruitment::InternshipProgram and no column for one. A student who wants a
# published position uses the shipped application path instead, so exactly one
# record type covers each situation and the two never overlap (SPEC-0041).
#
# Approval records a decision and nothing more. The placement that would
# represent the internship itself belongs to a later increment, so nothing here
# may be read as "the internship started" or "the internship finished".
class InternshipRequest < ApplicationRecord
  STATUSES = %w[ draft submitted under_review approved rejected withdrawn ].freeze
  OPEN_STATUSES = %w[ draft submitted under_review ].freeze
  DECIDED_STATUSES = %w[ approved rejected ].freeze
  # Who may act on an incoming request: the company-facing roles that already
  # author and review recruitment work. Mentors evaluate internships; they do
  # not decide who is invited into one.
  DECIDER_ROLES = Recruitment::InternshipProgram::AUTHOR_ROLES
  # Turning acceptance on is a company-policy act, so it sits with the two
  # accountable roles rather than everyone who can review.
  SETTING_ROLES = %w[ owner company_reviewer ].freeze
  TRANSITIONS = {
    "draft" => %w[ submitted withdrawn ],
    "submitted" => %w[ under_review approved rejected withdrawn ],
    "under_review" => %w[ approved rejected withdrawn ],
    "approved" => [],
    "rejected" => [],
    "withdrawn" => []
  }.freeze

  belongs_to :organization, inverse_of: :internship_requests
  belongs_to :student, class_name: "User", inverse_of: :internship_requests
  belongs_to :decided_by, class_name: "User", optional: true, inverse_of: :decided_internship_requests

  attr_accessor :status_transition_context

  normalizes :motivation, with: ->(value) { value.to_s.strip }
  normalizes :learning_goals, with: ->(value) { value.to_s.strip }
  normalizes :decision_reason, with: ->(value) { value.to_s.strip.presence }
  normalizes :status, with: ->(value) { value.to_s.strip.downcase }

  validates :motivation, presence: true, length: { maximum: 5_000 }
  validates :learning_goals, presence: true, length: { maximum: 5_000 }
  validates :decision_reason, length: { maximum: 5_000 }
  validates :status, inclusion: { in: STATUSES }
  validate :student_account
  validate :organization_accepts_requests, on: :create
  validate :initial_status_is_draft, on: :create
  validate :one_open_request_per_organization
  validate :status_change_requires_transition_context, on: :update
  validate :decided_request_is_immutable, on: :update
  validate :rejection_states_a_reason

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :open_requests, -> { where(status: OPEN_STATUSES) }
  scope :awaiting_company, -> { where(status: %w[ submitted under_review ]) }

  def draft? = status == "draft"
  def submitted? = status == "submitted"
  def under_review? = status == "under_review"
  def approved? = status == "approved"
  def rejected? = status == "rejected"
  def withdrawn? = status == "withdrawn"

  def open? = OPEN_STATUSES.include?(status)
  def decided? = DECIDED_STATUSES.include?(status)
  def editable_by_student? = draft?

  # Re-derived from the database rather than a loaded association, so a
  # membership revoked mid-session fails closed.
  def decidable_by?(user)
    return false unless user && Organization.active.where(id: organization_id).exists?

    OrganizationMembership.where(organization_id:, user_id: user.id, status: "active",
                                 role: DECIDER_ROLES).exists?
  end

  def visible_to?(user)
    return false if user.blank?

    student_id == user.id || decidable_by?(user)
  end

  def submit!(actor:)
    raise ActiveRecord::RecordInvalid, self unless actor == student && draft?

    transition!("submitted", actor:, stamps: { submitted_at: Time.current })
  end

  def withdraw!(actor:)
    raise ActiveRecord::RecordInvalid, self unless actor == student && open?

    transition!("withdrawn", actor:, stamps: { withdrawn_at: Time.current })
  end

  def start_review!(actor:)
    transition!("under_review", actor:, stamps: { reviewed_at: Time.current }, company: true)
  end

  def approve!(actor:)
    transition!("approved", actor:, company: true,
                stamps: { decided_at: Time.current, decided_by: actor })
  end

  def reject!(actor:, reason:)
    transition!("rejected", actor:, company: true,
                stamps: { decided_at: Time.current, decided_by: actor, decision_reason: reason })
  end

  private
    def transition!(target, actor:, stamps: {}, company: false)
      updated = self.class.transaction do
        locked = self.class.lock.find(id)
        raise ActiveRecord::RecordInvalid, locked unless TRANSITIONS.fetch(locked.status, []).include?(target)
        raise ActiveRecord::RecordInvalid, locked if company && !locked.decidable_by?(actor)

        locked.status_transition_context = true
        locked.update!(status: target, **stamps)
        locked
      end
      assign_attributes(updated.attributes)
      self
    end

    def student_account
      errors.add(:student, :invalid) unless student&.student?
    end

    def organization_accepts_requests
      return if organization.blank?
      return if organization.active? && organization.accepts_internship_requests?

      errors.add(:organization, :invalid)
    end

    def initial_status_is_draft
      errors.add(:status, :invalid) unless draft?
    end

    # The partial unique index is the real guarantee; this turns the race into a
    # readable validation error for everyone who is not racing.
    def one_open_request_per_organization
      return if organization_id.blank? || student_id.blank? || !open?

      duplicate = self.class.open_requests.where(organization_id:, student_id:).where.not(id:).exists?
      errors.add(:base, :taken) if duplicate
    end

    def status_change_requires_transition_context
      return unless will_save_change_to_status?
      return if status_transition_context

      errors.add(:status, :invalid)
    end

    def decided_request_is_immutable
      errors.add(:base, :invalid) if DECIDED_STATUSES.include?(status_was) || status_was == "withdrawn"
    end

    def rejection_states_a_reason
      errors.add(:decision_reason, :blank) if rejected? && decision_reason.blank?
    end
end
