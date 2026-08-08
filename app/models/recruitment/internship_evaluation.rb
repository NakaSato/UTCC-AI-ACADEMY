module Recruitment
  class InternshipEvaluation < ApplicationRecord
    self.table_name = "recruitment_internship_evaluations"

    STATUSES = %w[ draft submitted ].freeze
    REVIEWER_ROLES = %w[ owner recruiter hiring_manager mentor ].freeze

    belongs_to :application, class_name: "Recruitment::InternshipApplication", inverse_of: :evaluation
    belongs_to :evaluator, class_name: "User", inverse_of: :internship_evaluations

    normalizes :status, with: ->(value) { value.to_s.strip.downcase }
    normalizes :feedback, :next_steps, with: ->(value) { value.to_s.strip }

    validates :status, inclusion: { in: STATUSES }
    validates :rating, inclusion: { in: 1..5 }, allow_nil: true
    validates :feedback, :next_steps, length: { maximum: 10_000 }
    validates :learning_outcomes_met, inclusion: { in: [ true, false ] }, allow_nil: true
    validates :submitted_at, presence: true, if: :submitted?
    validates :rating, :learning_outcomes_met, :feedback, :next_steps, presence: true, if: :submitted?
    validate :accepted_application
    validate :evaluator_can_review
    validate :organization_is_active

    def draft? = status == "draft"
    def submitted? = status == "submitted"

    def submit!
      self.status = "submitted"
      self.submitted_at ||= Time.current
      save!
    end

    private
      def accepted_application
        return if application.blank?
        return if application.accepted?

        errors.add(:application, :invalid)
      end

      def evaluator_can_review
        return if evaluator.blank? || application.blank?
        return if evaluator.admin?

        membership = application.program.organization.memberships.active.find_by(user_id: evaluator_id)
        return if membership.present? && REVIEWER_ROLES.include?(membership.role) &&
          (membership.role != "mentor" || application.program.mentor_id == evaluator_id)

        errors.add(:evaluator, :invalid)
      end

      def organization_is_active
        return if application.blank?

        errors.add(:application, :invalid) unless Organization.where(
          id: application.program.organization_id, status: "active"
        ).exists?
      end
  end
end
