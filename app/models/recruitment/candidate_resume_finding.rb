module Recruitment
  class CandidateResumeFinding < ApplicationRecord
    self.table_name = "recruitment_candidate_resume_findings"

    KINDS = %w[ skill tool experience seniority qualification ats_signal skill_gap strength uncertainty ].freeze
    STATUSES = %w[ pending edited accepted rejected ].freeze
    ACTIONABLE_STATUSES = %w[ pending edited ].freeze
    SOURCE_TYPES = %w[ resume_text resume_metadata rules_inference ].freeze
    FACT_KIND_MAP = { "skill" => "skill", "tool" => "skill", "experience" => "experience",
                      "qualification" => "certification" }.freeze

    belongs_to :analysis, class_name: "Recruitment::CandidateResumeAnalysis", inverse_of: :findings
    belongs_to :applied_fact, class_name: "CandidateProfileFact", optional: true
    belongs_to :reviewed_by, class_name: "User", optional: true

    normalizes :kind, :status, :source_type, with: ->(value) { value.to_s.strip.downcase }
    normalizes :title, :detail, :evidence, with: ->(value) { value.to_s.strip }

    validates :kind, inclusion: { in: KINDS }
    validates :status, inclusion: { in: STATUSES }
    validates :source_type, inclusion: { in: SOURCE_TYPES }
    validates :title, :evidence, presence: true
    validates :title, length: { maximum: 240 }
    validates :detail, length: { maximum: 4_000 }
    validates :confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validate :reviewer_owns_profile

    scope :ordered, -> { order(position: :asc, id: :asc) }

    def actionable? = ACTIONABLE_STATUSES.include?(status)
    def accepted? = status == "accepted"

    def fact_kind = FACT_KIND_MAP[kind]

    def edit!(attributes, reviewer:)
      raise ActiveRecord::RecordInvalid, self unless actionable?

      transaction do
        update!(attributes.slice(:title, :detail).merge(status: "edited", reviewed_by: reviewer, reviewed_at: Time.current))
        analysis.review!(reviewer:)
      end
    end

    def accept!(reviewer:)
      raise ActiveRecord::RecordInvalid, self unless actionable?

      transaction do
        update!(status: "accepted", reviewed_by: reviewer, reviewed_at: Time.current)
        analysis.review!(reviewer:)
      end
    end

    def reject!(reviewer:)
      raise ActiveRecord::RecordInvalid, self unless actionable?

      transaction do
        update!(status: "rejected", reviewed_by: reviewer, reviewed_at: Time.current)
        analysis.review!(reviewer:)
      end
    end

    private
      def reviewer_owns_profile
        return if reviewed_by.blank? || analysis.blank?

        errors.add(:reviewed_by, :invalid) unless reviewed_by_id == analysis.candidate_profile.user_id
      end
  end
end
