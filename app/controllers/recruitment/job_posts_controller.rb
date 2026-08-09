module Recruitment
  class JobPostsController < ApplicationController
    def index
      if params[:organization_id]
        @organization = readable_organization
        @job_posts = @organization.job_posts.order(updated_at: :desc, id: :desc)
        @public = false
        @can_create = Current.user.admin? || @organization.memberships.active.exists?(user_id: Current.user.id,
                                                                                         role: Recruitment::JobPost::AUTHOR_ROLES)
      else
        @filters = params.permit(:query, :category, :employment_type, :location, :remote_policy).to_h
        @job_categories = Recruitment::JobPost.published_for_candidates.where.not(category: "").distinct.order(:category).pluck(:category)
        @job_posts = Recruitment::JobDiscovery.search(@filters)
        @public = true
        if Current.user.student?
          @saved_job_ids = Current.user.saved_jobs.where(job_post_id: @job_posts.map(&:id)).pluck(:job_post_id)
          @recommendations = Recruitment::JobDiscovery.recommend(user: Current.user)
          Recruitment::JobAlertNotifier.call(user: Current.user, recommendations: @recommendations)
        else
          @saved_job_ids = []
          @recommendations = []
        end
      end
    end

    def new
      @organization = authoring_organization
      @job_post = @organization.job_posts.new
    end

    def create
      @organization = authoring_organization
      @job_post = @organization.job_posts.new(job_post_params)
      @job_post.creator = Current.user
      @job_post.save!
      AuditEvent.record("recruitment_job_post_created", organization: @organization.name,
                        job: @job_post.title.presence || t("recruitment.jobs.untitled"))
      redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                  notice: t("flash.recruitment_job_created")
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end

    def show
      if params[:organization_id]
        @organization = readable_organization
        @job_post = @organization.job_posts.find(params[:id])
        @public = false
        assign_permissions
        @suggestions = @job_post.suggestions.newest_first
        @can_review_suggestions = Current.user.admin? || @organization.memberships.active.exists?(user_id: Current.user.id,
                                                                                                   role: Recruitment::JobPost::AUTHOR_ROLES)
        @can_generate_suggestions = @can_review_suggestions && @job_post.editable?
        @can_review_applications = @can_review_suggestions
        @application_count = @can_review_applications ? @job_post.applications.count : 0
      else
        @job_post = Recruitment::JobPost.published_for_candidates.find(params[:id])
        @public = true
        @saved_job = Current.user.student? ? Current.user.saved_jobs.find_by(job_post_id: @job_post.id) : nil
        @application = Current.user.student? ? Current.user.job_applications.find_by(job_post_id: @job_post.id) : nil
        @match_preview = Recruitment::JobMatchPreview.call(user: Current.user, job_post: @job_post)
      end
    end

    def edit
      load_editable_job_post
    end

    def update
      return unless load_editable_job_post
      @job_post.assign_attributes(job_post_params)
      @job_post.save!
      AuditEvent.record("recruitment_job_post_updated", organization: @organization.name,
                        job: @job_post.title.presence || t("recruitment.jobs.untitled"))
      redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                  notice: t("flash.recruitment_job_saved")
    rescue ActiveRecord::StaleObjectError
      @job_post = @organization.job_posts.find(@job_post.id)
      @conflict = true
      render :edit, status: :conflict
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_entity
    end

    def destroy
      @organization = authorizing_organization(Recruitment::JobPost::APPROVER_ROLES)
      @job_post = @organization.job_posts.find(params[:id])
      return redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                         alert: t("flash.recruitment_job_delete_forbidden") unless @job_post.draft?

      title = @job_post.title.presence || t("recruitment.jobs.untitled")
      @job_post.destroy!
      AuditEvent.record("recruitment_job_post_deleted", organization: @organization.name, job: title)
      redirect_to recruitment_organization_job_posts_path(@organization),
                  notice: t("flash.recruitment_job_deleted")
    end

    def submit
      transition_job("review", Recruitment::JobPost::AUTHOR_ROLES, "submitted")
    end

    def request_changes
      transition_job("draft", Recruitment::JobPost::APPROVER_ROLES, "changes_requested")
    end

    def publish
      transition_job("published", Recruitment::JobPost::APPROVER_ROLES, "published")
    end

    def pause
      transition_job("paused", Recruitment::JobPost::APPROVER_ROLES, "paused")
    end

    def close
      transition_job("closed", Recruitment::JobPost::APPROVER_ROLES, "closed")
    end

    def archive
      transition_job("archived", Recruitment::JobPost::APPROVER_ROLES, "archived")
    end

    private
      def job_post_params
        params.expect(recruitment_job_post: [
          :title, :summary, :description, :category, :department, :team, :seniority,
          :employment_type, :location, :remote_policy, :salary_min, :salary_max,
          :currency, :closes_on, :hiring_reason, :positions_count, :lock_version
        ])
      end

      def readable_organization
        organization = Organization.active.from_param!(params[:organization_id])
        return organization if Current.user.admin?
        return organization if organization.memberships.active.exists?(user_id: Current.user.id)

        raise ActiveRecord::RecordNotFound
      end

      def authoring_organization
        authorizing_organization(Recruitment::JobPost::AUTHOR_ROLES)
      end

      def authorizing_organization(roles)
        organization = Organization.active.from_param!(params[:organization_id])
        return organization if Current.user.admin?
        return organization if organization.memberships.active.exists?(user_id: Current.user.id, role: roles)

        raise ActiveRecord::RecordNotFound
      end

      def load_editable_job_post
        @organization = authoring_organization
        @job_post = @organization.job_posts.find(params[:id])
        return true if @job_post.editable?

        redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                    alert: t("flash.recruitment_job_not_editable")
        false
      end

      def assign_permissions
        author = Current.user.admin? || @organization.memberships.active.exists?(user_id: Current.user.id,
                                                                                   role: Recruitment::JobPost::AUTHOR_ROLES)
        approver = Current.user.admin? || @organization.memberships.active.exists?(user_id: Current.user.id,
                                                                                     role: Recruitment::JobPost::APPROVER_ROLES)
        @can_edit = author && @job_post.editable?
        @can_submit = author && @job_post.draft?
        @can_request_changes = approver && @job_post.review?
        @can_publish = approver && @job_post.review?
        @can_pause = approver && @job_post.published?
        @can_close = approver && [ "published", "paused" ].include?(@job_post.status)
        @can_archive = approver && [ "draft", "review", "paused", "closed" ].include?(@job_post.status)
        @can_delete = approver && @job_post.draft?
      end

      def transition_job(target, roles, audit_suffix)
        @organization = authorizing_organization(roles)
        @job_post = @organization.job_posts.find(params[:id])
        previous_status = @job_post.status
        @job_post.transition_to!(target)
        AuditEvent.record("recruitment_job_post_#{audit_suffix}", organization: @organization.name,
                          job: @job_post.title.presence || t("recruitment.jobs.untitled"),
                          from_status: previous_status, to_status: @job_post.status)
        redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                    notice: t("flash.recruitment_job_#{audit_suffix}")
      rescue ActiveRecord::RecordInvalid
        redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                    alert: t("flash.recruitment_job_transition_forbidden")
      end
  end
end
