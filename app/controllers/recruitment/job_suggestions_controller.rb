module Recruitment
  class JobSuggestionsController < ApplicationController
    def create
      load_author_job
      suggestions = JobSuggestionGenerator.call(job_post: @job_post, requested_by: Current.user)
      AuditEvent.record("recruitment_job_suggestions_generated", organization: @organization.name,
                        job: @job_post.title.presence || t("recruitment.jobs.untitled"), count: suggestions.size)
      redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                  notice: t("flash.recruitment_job_suggestions_generated", count: suggestions.size)
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                  alert: t("flash.recruitment_job_suggestions_unavailable")
    end

    def update
      load_reviewable_job
      suggestion = find_suggestion
      suggestion.edit!(suggestion_params[:content], reviewer: Current.user)
      AuditEvent.record("recruitment_job_suggestion_edited", organization: @organization.name,
                        job: @job_post.title.presence || t("recruitment.jobs.untitled"), suggestion: suggestion.kind)
      redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                  notice: t("flash.recruitment_job_suggestion_edited")
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                  alert: t("flash.recruitment_job_suggestion_unavailable")
    end

    def accept
      review_suggestion("accepted") { find_suggestion.accept!(reviewer: Current.user) }
    end

    def reject
      review_suggestion("rejected") { find_suggestion.reject!(reviewer: Current.user) }
    end

    def regenerate
      load_author_job
      suggestion = find_suggestion
      JobSuggestionGenerator.regenerate!(suggestion:, requested_by: Current.user)
      AuditEvent.record("recruitment_job_suggestion_regenerated", organization: @organization.name,
                        job: @job_post.title.presence || t("recruitment.jobs.untitled"), suggestion: suggestion.kind)
      redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                  notice: t("flash.recruitment_job_suggestion_regenerated")
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                  alert: t("flash.recruitment_job_suggestion_unavailable")
    end

    private
      def suggestion_params
        params.expect(recruitment_job_post_suggestion: [ :content ])
      end

      def load_author_job
        load_job
        raise ActiveRecord::RecordNotFound unless @job_post.editable?
      end

      def load_reviewable_job
        load_job
        raise ActiveRecord::RecordNotFound if @job_post.closed? || @job_post.archived?
      end

      def load_job
        @organization = Organization.active.find(params[:organization_id])
        unless Current.user.admin? || @organization.memberships.active.exists?(user_id: Current.user.id,
                                                                                 role: Recruitment::JobPost::AUTHOR_ROLES)
          raise ActiveRecord::RecordNotFound
        end
        @job_post = @organization.job_posts.find(params[:job_post_id] || params[:id])
      end

      def find_suggestion
        @job_post.suggestions.find(params[:id])
      end

      def review_suggestion(action)
        load_reviewable_job
        suggestion = find_suggestion
        yield
        AuditEvent.record("recruitment_job_suggestion_#{action}", organization: @organization.name,
                          job: @job_post.title.presence || t("recruitment.jobs.untitled"), suggestion: suggestion.kind)
        redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                    notice: t("flash.recruitment_job_suggestion_#{action}")
      rescue ActiveRecord::RecordInvalid
        redirect_to recruitment_organization_job_post_path(@organization, @job_post),
                    alert: t("flash.recruitment_job_suggestion_unavailable")
      end
  end
end
