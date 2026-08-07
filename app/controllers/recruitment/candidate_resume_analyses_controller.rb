module Recruitment
  class CandidateResumeAnalysesController < ApplicationController
    allow_only :student

    def create
      profile = current_profile
      analysis = CandidateResumeAnalysisGenerator.call(candidate_profile: profile, requested_by: Current.user)
      AuditEvent.record("recruitment_resume_analysis_generated", filename: profile.resume.filename.to_s,
                        finding_count: analysis.findings.size)
      redirect_to edit_recruitment_candidate_profile_path,
                  notice: t("flash.recruitment_resume_analysis_generated", count: analysis.findings.size)
    rescue ActiveRecord::RecordInvalid
      redirect_to edit_recruitment_candidate_profile_path,
                  alert: t("flash.recruitment_resume_analysis_unavailable")
    end

    def update
      finding = load_finding
      finding.edit!(finding_params, reviewer: Current.user)
      AuditEvent.record("recruitment_resume_finding_edited", kind: finding.kind)
      redirect_to edit_recruitment_candidate_profile_path,
                  notice: t("flash.recruitment_resume_finding_edited")
    rescue ActiveRecord::RecordInvalid
      redirect_to edit_recruitment_candidate_profile_path,
                  alert: t("flash.recruitment_resume_finding_unavailable")
    end

    def accept
      review_finding("accepted") { load_finding.accept!(reviewer: Current.user) }
    end

    def reject
      review_finding("rejected") { load_finding.reject!(reviewer: Current.user) }
    end

    def apply
      analysis = load_analysis
      analysis.apply!(reviewer: Current.user)
      AuditEvent.record("recruitment_resume_analysis_applied", finding_count: analysis.findings.where(status: "accepted").count)
      redirect_to edit_recruitment_candidate_profile_path,
                  notice: t("flash.recruitment_resume_analysis_applied")
    rescue ActiveRecord::RecordInvalid
      redirect_to edit_recruitment_candidate_profile_path,
                  alert: t("flash.recruitment_resume_analysis_unavailable")
    end

    private
      def current_profile
        Current.user.candidate_profile || raise(ActiveRecord::RecordNotFound)
      end

      def load_analysis
        current_profile.resume_analyses.find(params[:analysis_id] || params[:id])
      end

      def load_finding
        load_analysis.findings.find(params[:id])
      end

      def finding_params
        params.expect(recruitment_candidate_resume_finding: [ :title, :detail ])
      end

      def review_finding(action)
        finding = load_finding
        yield
        AuditEvent.record("recruitment_resume_finding_#{action}", kind: finding.kind)
        redirect_to edit_recruitment_candidate_profile_path,
                    notice: t("flash.recruitment_resume_finding_#{action}")
      rescue ActiveRecord::RecordInvalid
        redirect_to edit_recruitment_candidate_profile_path,
                    alert: t("flash.recruitment_resume_finding_unavailable")
      end
  end
end
