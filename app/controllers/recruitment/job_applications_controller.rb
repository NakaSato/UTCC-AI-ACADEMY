module Recruitment
  class JobApplicationsController < ApplicationController
    def index
      if params[:organization_id]
        load_reviewable_job
        @applications = @job_post.applications.includes(:candidate, :events).newest_first
        @organization_view = true
      else
        require_student
        @applications = Current.user.job_applications.includes(:job_post, :events).newest_first
        @candidate_view = true
      end
    end

    def show
      if params[:organization_id]
        load_reviewable_job
        @application = @job_post.applications.includes(:candidate, :events, :messages).find(params[:id])
        @assistant = Recruitment::JobApplicationAssistant.call(application: @application, viewer: Current.user)
        @organization_view = true
      else
        require_student
        @application = Current.user.job_applications.includes(:job_post, :events, :messages).find(params[:id])
        @candidate_assistant = Recruitment::CandidateApplicationAssistant.call(application: @application,
                                                                               viewer: Current.user)
        @candidate_view = true
      end
      @messages = @application.messages.includes(:sender).order(sent_at: :asc, id: :asc)
    end

    def create
      require_student
      @job_post = Recruitment::JobPost.published_for_candidates.find(params[:id])
      @application = Recruitment::JobApplication.submit!(job_post: @job_post, candidate: Current.user,
                                                          statement: application_params[:statement])
      AuditEvent.record("recruitment_job_application_created", organization: @job_post.organization.name,
                        job: @job_post.title, application: @application.id)
      redirect_to recruitment_job_application_path(@application), notice: t("flash.recruitment_job_application_created")
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_job_path(@job_post || params[:id]), alert: t("flash.recruitment_job_application_unavailable")
    end

    def withdraw
      require_student
      @application = Current.user.job_applications.includes(:job_post).find(params[:id])
      @application.withdraw!(actor: Current.user)
      AuditEvent.record("recruitment_job_application_withdrawn", organization: @application.job_post.organization.name,
                        job: @application.job_post.title, application: @application.id)
      redirect_to recruitment_job_application_path(@application), notice: t("flash.recruitment_job_application_withdrawn")
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_job_application_path(@application || params[:id]),
                  alert: t("flash.recruitment_job_application_unavailable")
    end

    def transition
      load_reviewable_job
      @application = @job_post.applications.find(params[:id])
      @application.transition_to!(transition_params[:status], actor: Current.user, note: transition_params[:note],
                                  lock_version: transition_params[:lock_version])
      AuditEvent.record("recruitment_job_application_transitioned", organization: @organization.name,
                        job: @job_post.title, application: @application.id,
                        from_status: @application.events.order(:id).last.from_status,
                        to_status: @application.status)
      redirect_to recruitment_organization_job_post_application_path(@organization, @job_post, @application),
                  notice: t("flash.recruitment_job_application_transitioned")
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
      redirect_to recruitment_organization_job_post_application_path(@organization, @job_post, @application || params[:id]),
                  alert: t("flash.recruitment_job_application_transition_unavailable")
    end

    def message
      redirect_path = nil
      if params[:organization_id]
        load_reviewable_job
        @application = @job_post.applications.find(params[:id])
        redirect_path = recruitment_organization_job_post_application_path(@organization, @job_post, @application)
      else
        require_student
        @application = Current.user.job_applications.includes(:job_post).find(params[:id])
        redirect_path = recruitment_job_application_path(@application)
      end

      @application.messages.create!(sender: Current.user, body: message_params[:body])
      redirect_to redirect_path, notice: t("flash.recruitment_job_application_message_created")
    rescue ActiveRecord::RecordInvalid
      redirect_to redirect_path || recruitment_job_application_path(@application || params[:id]),
                  alert: t("flash.recruitment_job_application_message_unavailable")
    end

    private
      def application_params
        params.expect(recruitment_job_application: [ :statement ])
      end

      def transition_params
        params.expect(recruitment_job_application: [ :status, :note, :lock_version ])
      end

      def message_params
        params.expect(recruitment_job_application_message: [ :body ])
      end

      def require_student
        raise ActiveRecord::RecordNotFound unless Current.user&.student?
      end

      def load_reviewable_job
        @organization = Organization.active.find(params[:organization_id])
        permitted = Current.user.admin? || @organization.memberships.active.exists?(user_id: Current.user.id,
                                                                                    role: Recruitment::JobApplication::REVIEWER_ROLES)
        raise ActiveRecord::RecordNotFound unless permitted

        @job_post = @organization.job_posts.find(params[:job_post_id])
      end
  end
end
