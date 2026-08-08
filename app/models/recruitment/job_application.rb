module Recruitment
  class JobApplication < ApplicationRecord
    self.table_name = "recruitment_job_applications"

    STATUSES = %w[ submitted screening interview offer accepted rejected withdrawn ].freeze
    CANDIDATE_WITHDRAWABLE_STATUSES = %w[ submitted screening interview ].freeze
    REVIEWER_ROLES = Recruitment::JobPost::AUTHOR_ROLES
    TRANSITIONS = {
      "submitted" => %w[ screening rejected withdrawn ],
      "screening" => %w[ submitted interview rejected withdrawn ],
      "interview" => %w[ screening offer rejected withdrawn ],
      "offer" => %w[ interview accepted rejected withdrawn ],
      "accepted" => [],
      "rejected" => [],
      "withdrawn" => []
    }.freeze

    belongs_to :job_post, class_name: "Recruitment::JobPost", inverse_of: :applications
    belongs_to :candidate, class_name: "User", inverse_of: :job_applications
    belongs_to :reviewed_by, class_name: "User", optional: true, inverse_of: :reviewed_job_applications
    has_many :events, class_name: "Recruitment::JobApplicationEvent", dependent: :restrict_with_exception,
                      inverse_of: :job_application
    has_many :messages, class_name: "Recruitment::JobApplicationMessage", dependent: :restrict_with_exception,
                        inverse_of: :job_application
    attr_accessor :status_transition_context

    normalizes :status, with: ->(value) { value.to_s.strip.downcase }
    normalizes :statement, with: ->(value) { value.to_s.strip }

    validates :status, inclusion: { in: STATUSES }
    validates :statement, length: { maximum: 10_000 }
    validates :application_snapshot, presence: true
    validates :applied_at, presence: true
    validates :candidate_id, uniqueness: { scope: :job_post_id }
    validate :candidate_account
    validate :reviewer_can_manage
    validate :submission_boundary, on: :create
    validate :initial_status_is_submitted, on: :create
    validate :status_change_requires_transition_context, on: :update

    scope :newest_first, -> { order(created_at: :desc, id: :desc) }
    scope :pipeline, -> { order(:status, created_at: :asc, id: :asc) }

    before_validation :set_application_time, on: :create

    def self.submit!(job_post:, candidate:, statement:)
      profile = candidate.candidate_profile
      application = new(job_post:, candidate:, statement:, application_snapshot: profile&.export_payload || {})
      transaction do
        application.save!
        application.events.create!(actor: candidate, to_status: application.status, occurred_at: application.applied_at)
      end
      application
    end

    def submitted? = status == "submitted"
    def screening? = status == "screening"
    def interview? = status == "interview"
    def offer? = status == "offer"
    def accepted? = status == "accepted"
    def rejected? = status == "rejected"
    def withdrawn? = status == "withdrawn"
    def candidate_withdrawable? = CANDIDATE_WITHDRAWABLE_STATUSES.include?(status)

    def next_action
      return "withdrawn" if withdrawn?
      return "completed" if accepted? || rejected?

      status
    end

    def transition_to!(target, actor:, note: "", lock_version: nil)
      target = target.to_s.strip.downcase
      updated_application = self.class.transaction do
        locked_application = self.class.lock.find(id)
        raise ActiveRecord::StaleObjectError.new(locked_application, "update") if lock_version.present? &&
          locked_application.lock_version.to_i != lock_version.to_i
        raise ActiveRecord::RecordInvalid, locked_application unless locked_application.reviewer?(actor) &&
                                                                     TRANSITIONS.fetch(locked_application.status, []).include?(target)

        previous_status = locked_application.status
        locked_application.status_transition_context = true
        locked_application.update!(status: target, reviewed_by: actor, reviewed_at: Time.current)
        locked_application.events.create!(actor:, from_status: previous_status, to_status: target, note:,
                                          occurred_at: Time.current)
        locked_application
      end
      assign_attributes(updated_application.attributes)
      self
    end

    def withdraw!(actor:)
      raise ActiveRecord::RecordInvalid, self unless actor == candidate && candidate_withdrawable?

      updated_application = self.class.transaction do
        locked_application = self.class.lock.find(id)
        raise ActiveRecord::RecordInvalid, locked_application unless locked_application.candidate == actor &&
                                                                     locked_application.candidate_withdrawable?

        previous_status = locked_application.status
        locked_application.status_transition_context = true
        locked_application.update!(status: "withdrawn", withdrawn_at: Time.current)
        locked_application.events.create!(actor:, from_status: previous_status, to_status: "withdrawn",
                                          occurred_at: Time.current)
        locked_application
      end
      assign_attributes(updated_application.attributes)
      self
    end

    def reviewer?(user)
      return false unless user && job_post_id && Organization.active.where(id: job_post.organization_id).exists?
      return true if user.admin?

      OrganizationMembership.where(organization_id: job_post.organization_id, user_id: user.id,
                                  status: "active", role: REVIEWER_ROLES).exists?
    end

    private
      def set_application_time
        self.applied_at ||= Time.current
      end

      def candidate_account
        errors.add(:candidate, :invalid) unless candidate&.student?
      end

      def reviewer_can_manage
        return if reviewed_by.blank? || job_post.blank?
        return if reviewer?(reviewed_by)

        errors.add(:reviewed_by, :invalid)
      end

      def submission_boundary
        return if job_post.blank? || candidate.blank?
        visible_job = Recruitment::JobPost.published_for_candidates.where(id: job_post_id).exists?
        consented_profile = CandidateProfile.where(user_id: candidate_id, application_data_reuse_consent: true).exists?
        return if visible_job && candidate.student? && consented_profile

        errors.add(:base, :invalid)
      end

      def initial_status_is_submitted
        errors.add(:status, :invalid) unless status == "submitted"
      end

      def status_change_requires_transition_context
        return unless will_save_change_to_status?
        return if status_transition_context

        errors.add(:status, :invalid)
      end
  end
end
