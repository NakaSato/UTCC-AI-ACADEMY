module Recruitment
  class CandidateResumeAnalysis < ApplicationRecord
    self.table_name = "recruitment_candidate_resume_analyses"

    STATUSES = %w[ pending reviewed applied rejected ].freeze
    PROVIDERS = %w[ rules_preview ].freeze

    belongs_to :candidate_profile, inverse_of: :resume_analyses
    belongs_to :requested_by, class_name: "User", inverse_of: :requested_resume_analyses
    belongs_to :reviewed_by, class_name: "User", optional: true, inverse_of: :reviewed_resume_analyses
    has_many :findings, class_name: "Recruitment::CandidateResumeFinding", foreign_key: :analysis_id,
             dependent: :destroy, inverse_of: :analysis

    normalizes :status, :provider, with: ->(value) { value.to_s.strip.downcase }
    normalizes :source_label, :uncertainty, with: ->(value) { value.to_s.strip }

    validates :status, inclusion: { in: STATUSES }
    validates :provider, inclusion: { in: PROVIDERS }
    validates :source_label, :uncertainty, presence: true
    validates :generated_at, presence: true
    validate :requester_owns_profile
    validate :reviewer_owns_profile

    scope :newest_first, -> { order(generated_at: :desc, id: :desc) }

    before_validation :set_generation_time, on: :create

    def pending? = status == "pending"
    def reviewed? = status == "reviewed"
    def applied? = status == "applied"

    def review!(reviewer:)
      raise ActiveRecord::RecordInvalid, self unless pending? || reviewed?

      update!(status: "reviewed", reviewed_by: reviewer, reviewed_at: Time.current)
    end

    def apply!(reviewer:)
      raise ActiveRecord::RecordInvalid, self unless pending? || reviewed?

      accepted_findings = findings.where(status: "accepted", applied_fact_id: nil).ordered
      accepted_fact_findings = accepted_findings.select(&:fact_kind)
      raise ActiveRecord::RecordInvalid, self if accepted_fact_findings.none?

      transaction do
        accepted_fact_findings.each do |finding|
          fact_kind = finding.fact_kind
          fact = candidate_profile.facts.create!(
            kind: fact_kind,
            title: finding.title,
            detail: [ finding.detail.presence, "Source evidence: #{finding.evidence}" ].compact.join("\n\n"),
            source: "document_extracted",
            confidence: finding.confidence
          )
          finding.update!(applied_fact: fact)
        end

        update!(status: "applied", reviewed_by: reviewer, reviewed_at: Time.current, applied_at: Time.current)
      end
    end

    private
      def set_generation_time
        self.generated_at ||= Time.current
      end

      def requester_owns_profile
        return if requested_by.blank? || candidate_profile.blank?

        errors.add(:requested_by, :invalid) unless requested_by_id == candidate_profile.user_id
      end

      def reviewer_owns_profile
        return if reviewed_by.blank? || candidate_profile.blank?

        errors.add(:reviewed_by, :invalid) unless reviewed_by_id == candidate_profile.user_id
      end
  end
end
