module Recruitment
  class CandidateResumeAnalysisGenerator
    PROVIDER = "rules_preview"
    SOURCE_LABEL = "Rules-based preview from candidate-controlled resume inputs; no external model was used."
    UNCERTAINTY = "This preview is not a hiring judgment. Plain-text resumes use simple section rules; PDF and Word files record metadata only until an approved text-extraction provider is connected. Review every finding before applying it."
    TEXT_CONTENT_TYPES = %w[ text/plain ].freeze
    MAX_TEXT_BYTES = 1.megabyte
    SECTION_LABELS = {
      "skills" => "skill", "skill" => "skill", "tools" => "tool", "technologies" => "tool",
      "tech stack" => "tool", "experience" => "experience", "work experience" => "experience",
      "education" => "qualification", "qualifications" => "qualification", "certifications" => "qualification",
      "languages" => "skill"
    }.freeze

    def self.call(candidate_profile:, requested_by:)
      new(candidate_profile:, requested_by:).call
    end

    def initialize(candidate_profile:, requested_by:)
      @candidate_profile = candidate_profile
      @requested_by = requested_by
    end

    def call
      raise ActiveRecord::RecordInvalid, @candidate_profile unless @candidate_profile.resume.attached?
      raise ActiveRecord::RecordInvalid, @candidate_profile unless @candidate_profile.user_id == @requested_by.id

      Recruitment::CandidateResumeAnalysis.transaction do
        analysis = @candidate_profile.resume_analyses.create!(
          requested_by: @requested_by,
          provider: PROVIDER,
          source_label: SOURCE_LABEL,
          uncertainty: UNCERTAINTY,
          source_context: source_context
        )
        findings_for(analysis).each { |attributes| analysis.findings.create!(attributes) }
        analysis
      end
    end

    private
      def findings_for(analysis)
        findings = text_findings
        findings = metadata_findings if findings.empty?
        findings << {
          kind: "strength", title: "Candidate-controlled source trail", detail: "Reviewers can see which findings came from the resume and which are rules-based inferences.",
          evidence: "Analysis source: #{source_context.fetch("filename")}", source_type: "rules_inference", confidence: 1.0,
          inferred: true, position: findings.length
        }
        findings << {
          kind: "uncertainty", title: "Human review required", detail: UNCERTAINTY,
          evidence: "Provider: #{PROVIDER}", source_type: "rules_inference", confidence: 1.0,
          inferred: true, position: findings.length
        }
        findings
      end

      def text_findings
        return [] unless text_resume?

        lines = resume_text.lines.map(&:strip).reject(&:blank?)
        findings = []
        lines.each do |line|
          match = line.match(/\A([^:]{2,40}):\s*(.+)\z/)
          next unless match

          label = match[1].downcase.gsub(/\s+/, " ")
          kind = SECTION_LABELS[label]
          next unless kind

          values = match[2].split(/[,;|]/).map { |value| value.strip }.select { |value| value.length.between?(2, 240) }
          values = [ match[2].strip ] if values.empty?
          values.first(12).each do |value|
            findings << {
              kind:, title: value, detail: "Detected under the #{label} section.", evidence: line,
              source_type: "resume_text", confidence: 0.75, inferred: false, position: findings.length
            }
          end
        end
        findings
      end

      def metadata_findings
        [
          { kind: "ats_signal", title: "Document metadata captured", detail: "The resume is attached and available for human review, but this file type was not parsed in the rules preview.",
            evidence: "#{source_context.fetch("filename")} (#{source_context.fetch("content_type")})", source_type: "resume_metadata", confidence: 0.2, inferred: false, position: 0 },
          { kind: "skill_gap", title: "Text extraction pending", detail: "Verify skills, experience, qualifications, and seniority manually before using this resume in an application.",
            evidence: "No document text was read by #{PROVIDER}.", source_type: "rules_inference", confidence: 1.0, inferred: true, position: 1 }
        ]
      end

      def source_context
        blob = @candidate_profile.resume.blob
        {
          "filename" => blob.filename.to_s,
          "content_type" => blob.content_type,
          "byte_size" => blob.byte_size,
          "checksum" => blob.checksum,
          "text_extracted" => text_resume?
        }
      end

      def text_resume?
        TEXT_CONTENT_TYPES.include?(@candidate_profile.resume.content_type) && @candidate_profile.resume.byte_size <= MAX_TEXT_BYTES
      end

      def resume_text
        @resume_text ||= @candidate_profile.resume.download.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      end
  end
end
