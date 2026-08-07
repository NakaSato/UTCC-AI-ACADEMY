module Recruitment
  class JobSuggestionGenerator
    KINDS = JobPostSuggestion::KINDS.freeze
    PROVIDER = "rules_preview"
    SOURCE_LABEL = "Rules-based preview from employer inputs; no external model was used."
    UNCERTAINTY = "Preview text requires human review and may not reflect the complete role."
    CONTEXT_FIELDS = %w[ title department employment_type location salary_min salary_max currency team seniority hiring_reason positions_count ].freeze

    def self.call(job_post:, requested_by:, only: nil)
      new(job_post:, requested_by:, only:).call
    end

    def self.regenerate!(suggestion:, requested_by:)
      JobPostSuggestion.transaction do
        suggestion.reject!(reviewer: requested_by) if suggestion.actionable?
        call(job_post: suggestion.job_post, requested_by:, only: suggestion.kind)
      end
    end

    def initialize(job_post:, requested_by:, only: nil)
      @job_post = job_post
      @requested_by = requested_by
      @kinds = only ? Array(only).map(&:to_s) : KINDS
    end

    def call
      raise ActiveRecord::RecordInvalid, @job_post unless @job_post.editable?
      raise ActiveRecord::RecordInvalid, @job_post unless @kinds.all? { |kind| KINDS.include?(kind) }

      JobPostSuggestion.transaction do
        @kinds.map do |kind|
          @job_post.suggestions.create!(
            requested_by: @requested_by,
            kind:,
            content: content_for(kind),
            provider: PROVIDER,
            source_label: SOURCE_LABEL,
            uncertainty: UNCERTAINTY,
            source_context: source_context
          )
        end
      end
    end

    private
      def content_for(kind)
        case kind
        when "summary"
          "Join #{@job_post.team.presence || @job_post.department.presence || "the team"} as a #{@job_post.seniority.presence || "key"} #{@job_post.title.presence || "role"} in #{@job_post.location.presence || "a flexible location"}."
        when "description"
          <<~TEXT.strip
            Work with the #{@job_post.team.presence || @job_post.department.presence || "team"} to deliver measurable results for this role.

            Responsibilities should be confirmed by the hiring team and tailored to the approved job scope.
          TEXT
        when "requirements"
          <<~TEXT.strip
            - Experience appropriate to the #{@job_post.seniority.presence || "stated"} seniority level
            - Ability to collaborate in the #{@job_post.remote_policy.presence || "defined"} work arrangement
            - Skills and qualifications confirmed by the hiring team
          TEXT
        when "interview_questions"
          <<~TEXT.strip
            - What evidence demonstrates success in a similar role?
            - How would you approach the main challenge described by the hiring team?
            - What support or context would help you do your best work?
          TEXT
        when "inclusive_language"
          "Review the final title and requirements for unnecessary barriers, unexplained jargon, and criteria that are not essential to the role."
        end
      end

      def source_context
        @job_post.attributes.slice(*CONTEXT_FIELDS)
      end
  end
end
