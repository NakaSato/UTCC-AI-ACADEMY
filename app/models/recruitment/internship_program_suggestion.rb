module Recruitment
  class InternshipProgramSuggestion < ApplicationRecord
    self.table_name = "recruitment_internship_program_suggestions"

    KINDS = %w[ description learning_roadmap mentor_guide evaluation_criteria final_project ].freeze
    STATUSES = %w[ pending edited accepted rejected ].freeze
    ACTIONABLE_STATUSES = %w[ pending edited ].freeze
    PROVIDERS = %w[ rules_preview ].freeze

    belongs_to :program, class_name: "Recruitment::InternshipProgram", inverse_of: :suggestions
    belongs_to :requested_by, class_name: "User", inverse_of: :requested_internship_program_suggestions
    belongs_to :reviewed_by, class_name: "User", optional: true, inverse_of: :reviewed_internship_program_suggestions

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

    scope :newest_first, -> { order(generated_at: :desc, id: :desc) }

    before_validation :set_generation_time, on: :create

    def actionable? = ACTIONABLE_STATUSES.include?(status)

    def edit!(new_content, reviewer:)
      raise ActiveRecord::RecordInvalid, self unless actionable?

      update!(content: new_content, status: "edited", reviewed_by: reviewer, reviewed_at: Time.current)
    end

    def accept!(reviewer:)
      raise ActiveRecord::RecordInvalid, self unless actionable?

      transaction do
        if kind == "description"
          raise ActiveRecord::RecordInvalid, self unless program.editable?

          program.update!(description: content)
        end
        update!(status: "accepted", reviewed_by: reviewer, reviewed_at: Time.current)
      end
    end

    def reject!(reviewer:)
      raise ActiveRecord::RecordInvalid, self unless actionable?

      update!(status: "rejected", reviewed_by: reviewer, reviewed_at: Time.current)
    end

    private
      def set_generation_time
        self.generated_at ||= Time.current
      end

      def requester_can_review
        return if requested_by.blank? || program.blank?
        return if requested_by.admin?
        return if program.organization.memberships.active.exists?(user_id: requested_by_id,
                                                                    role: Recruitment::InternshipProgram::AUTHOR_ROLES)

        errors.add(:requested_by, :invalid)
      end

      def reviewer_can_review
        return if reviewed_by.blank? || program.blank?
        return if reviewed_by.admin?
        return if program.organization.memberships.active.exists?(user_id: reviewed_by_id,
                                                                    role: Recruitment::InternshipProgram::AUTHOR_ROLES)

        errors.add(:reviewed_by, :invalid)
      end
  end
end
