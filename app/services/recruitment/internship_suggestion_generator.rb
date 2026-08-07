module Recruitment
  class InternshipSuggestionGenerator
    KINDS = InternshipProgramSuggestion::KINDS.freeze
    PROVIDER = "rules_preview"
    SOURCE_LABEL = "Rules-based preview from employer program inputs; no external model was used."
    UNCERTAINTY = "Preview text requires human review and may not reflect the complete program."
    CONTEXT_FIELDS = %w[ name department duration_weeks max_students required_skills learning_outcomes working_days remote_policy paid certificate_policy equipment_provided mentor_id ].freeze

    def self.call(program:, requested_by:, only: nil)
      new(program:, requested_by:, only:).call
    end

    def self.regenerate!(suggestion:, requested_by:)
      InternshipProgramSuggestion.transaction do
        suggestion.reject!(reviewer: requested_by) if suggestion.actionable?
        call(program: suggestion.program, requested_by:, only: suggestion.kind)
      end
    end

    def initialize(program:, requested_by:, only: nil)
      @program = program
      @requested_by = requested_by
      @kinds = only ? Array(only).map(&:to_s) : KINDS
    end

    def call
      raise ActiveRecord::RecordInvalid, @program unless @program.editable?
      raise ActiveRecord::RecordInvalid, @program unless @kinds.all? { |kind| KINDS.include?(kind) }

      InternshipProgramSuggestion.transaction do
        @kinds.map do |kind|
          @program.suggestions.create!(
            requested_by: @requested_by, kind:, content: content_for(kind), provider: PROVIDER,
            source_label: SOURCE_LABEL, uncertainty: UNCERTAINTY, source_context: source_context
          )
        end
      end
    end

    private
      def content_for(kind)
        case kind
        when "description"
          "Join #{@program.name.presence || "the program"} in #{@program.department.presence || "the organization"} for #{@program.duration_weeks} weeks of supervised, outcome-focused work."
        when "learning_roadmap"
          <<~TEXT.strip
            Weeks 1–2: understand the team, tools, and program goals.
            Weeks 3–8: practise the required skills through a mentored project.
            Final weeks: present evidence against the approved learning outcomes.
          TEXT
        when "mentor_guide"
          "Schedule a weekly check-in, connect feedback to the stated learning outcomes, and record evidence before the final evaluation."
        when "evaluation_criteria"
          "Evaluate progress against the published learning outcomes, quality of evidence, collaboration, and reflection. Confirm criteria with the mentor and academic owner."
        when "final_project"
          "Propose a scoped project that can be completed within #{@program.duration_weeks} weeks, demonstrates the required skills, and produces a reviewable final presentation."
        end
      end

      def source_context
        @program.attributes.slice(*CONTEXT_FIELDS)
      end
  end
end
