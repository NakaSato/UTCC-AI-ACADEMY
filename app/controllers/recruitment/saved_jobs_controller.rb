module Recruitment
  class SavedJobsController < ApplicationController
    allow_only :student

    def create
      job = discoverable_job
      saved_job = Current.user.saved_jobs.find_or_create_by!(job_post: job)
      AuditEvent.record("recruitment_job_saved", job: job.title) if saved_job.previously_new_record?
      redirect_back fallback_location: recruitment_jobs_path, notice: t("flash.recruitment_job_saved")
    rescue ActiveRecord::RecordInvalid
      redirect_back fallback_location: recruitment_jobs_path, alert: t("flash.recruitment_job_save_unavailable")
    end

    def destroy
      saved_job = Current.user.saved_jobs.find_by!(job_post_id: params[:id])
      title = saved_job.job_post.title
      saved_job.destroy!
      AuditEvent.record("recruitment_job_unsaved", job: title)
      redirect_back fallback_location: recruitment_jobs_path, notice: t("flash.recruitment_job_unsaved")
    end

    private
      def discoverable_job
        Recruitment::JobPost.published_for_candidates.find(params[:id])
      end
  end
end
