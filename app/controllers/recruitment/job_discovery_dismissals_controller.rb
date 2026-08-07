module Recruitment
  class JobDiscoveryDismissalsController < ApplicationController
    allow_only :student

    def create
      job = discoverable_job
      Current.user.job_discovery_dismissals.create!(job_post: job)
      AuditEvent.record("recruitment_job_recommendation_dismissed", job: job.title)
      redirect_back fallback_location: recruitment_jobs_path, notice: t("flash.recruitment_job_dismissed")
    rescue ActiveRecord::RecordInvalid
      redirect_back fallback_location: recruitment_jobs_path, alert: t("flash.recruitment_job_dismiss_unavailable")
    end

    def destroy
      dismissal = Current.user.job_discovery_dismissals.find_by!(job_post_id: params[:id])
      dismissal.destroy!
      redirect_back fallback_location: recruitment_jobs_path, notice: t("flash.recruitment_job_dismissal_removed")
    end

    private
      def discoverable_job
        Recruitment::JobPost.published_for_candidates.find(params[:id])
      end
  end
end
