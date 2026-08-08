module Recruitment
  class JobPostSuggestion < ApplicationRecord
    self.table_name = "recruitment_job_post_suggestions"

    KINDS = %w[ summary description requirements interview_questions inclusive_language ].freeze
    STATUSES = %w[ pending edited accepted rejected ].freeze
    ACTIONABLE_STATUSES = %w[ pending edited ].freeze
    PROVIDERS = %w[ rules_preview ].freeze

    belongs_to :job_post, class_name: "Recruitment::JobPost", inverse_of: :suggestions
    belongs_to :requested_by, class_name: "User", inverse_of: :requested_job_post_suggestions
    belongs_to :reviewed_by, class_name: "User", optional: true, inverse_of: :reviewed_job_post_suggestions

    normalizes :kind, :status, :provider, with: ->(value) { value.to_s.strip.downcase }
    normalizes :content, :source_label, :uncertainty, with: ->(value) { value.to_s.strip }

    validates :kind, inclusion: { in: KINDS }
    validates :status, inclusion: { in: STATUSES }
    validates :provider, inclusion: { in: PROVIDERS }
    validates :content, :source_label, :uncertainty, presence: true
    validates :content, length: { maximum: 20_000 }
    validates :generated_at, presence: true
    validate :requester_can_review
    validate :reviewer_can_review
    validate :organization_is_active

    scope :newest_first, -> { order(generated_at: :desc, id: :desc) }
    scope :actionable, -> { where(status: ACTIONABLE_STATUSES) }

    before_validation :set_generation_time, on: :create

    def actionable? = ACTIONABLE_STATUSES.include?(status)

    def edit!(new_content, reviewer:)
      raise ActiveRecord::RecordInvalid, self unless actionable? && reviewable_job?

      update!(content: new_content, status: "edited", reviewed_by: reviewer, reviewed_at: Time.current)
    end

    def accept!(reviewer:)
      raise ActiveRecord::RecordInvalid, self unless actionable? && reviewable_job? && job_post.editable?

      transaction do
        if %w[ summary description ].include?(kind)
          raise ActiveRecord::RecordInvalid, self unless job_post.editable?

          job_post.update!(kind => content)
        end
        update!(status: "accepted", reviewed_by: reviewer, reviewed_at: Time.current)
      end
    end

    def reject!(reviewer:)
      raise ActiveRecord::RecordInvalid, self unless actionable? && reviewable_job?

      update!(status: "rejected", reviewed_by: reviewer, reviewed_at: Time.current)
    end

    private
      def set_generation_time
        self.generated_at ||= Time.current
      end

      def reviewable_job?
        job_post.present? && job_post.organization.active? && !job_post.closed? && !job_post.archived?
      end

      def organization_is_active
        errors.add(:job_post, :invalid) if job_post.present? && !job_post.organization.active?
      end

      def requester_can_review
        return if requested_by.blank? || job_post.blank?
        return if requested_by.admin?
        return if job_post.organization.memberships.active.exists?(user_id: requested_by_id,
                                                                    role: Recruitment::JobPost::AUTHOR_ROLES)

        errors.add(:requested_by, :invalid)
      end

      def reviewer_can_review
        return if reviewed_by.blank? || job_post.blank?
        return if reviewed_by.admin?
        return if job_post.organization.memberships.active.exists?(user_id: reviewed_by_id,
                                                                    role: Recruitment::JobPost::AUTHOR_ROLES)

        errors.add(:reviewed_by, :invalid)
      end
  end
end
