module Recruitment
  class InternshipSuggestionsController < ApplicationController
    def create
      load_author_program
      suggestions = InternshipSuggestionGenerator.call(program: @program, requested_by: Current.user)
      audit("recruitment_internship_suggestions_generated", count: suggestions.size)
      redirect_to recruitment_organization_internship_program_path(@organization, @program),
                  notice: t("flash.recruitment_internship_suggestions_generated", count: suggestions.size)
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_organization_internship_program_path(@organization, @program),
                  alert: t("flash.recruitment_internship_suggestions_unavailable")
    end

    def update
      load_reviewable_program
      suggestion = find_suggestion
      suggestion.edit!(suggestion_params[:content], reviewer: Current.user)
      audit("recruitment_internship_suggestion_edited", suggestion: suggestion.kind)
      redirect_to recruitment_organization_internship_program_path(@organization, @program),
                  notice: t("flash.recruitment_internship_suggestion_edited")
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_organization_internship_program_path(@organization, @program),
                  alert: t("flash.recruitment_internship_suggestion_unavailable")
    end

    def accept
      review_suggestion("accepted") { find_suggestion.accept!(reviewer: Current.user) }
    end

    def reject
      review_suggestion("rejected") { find_suggestion.reject!(reviewer: Current.user) }
    end

    def regenerate
      load_author_program
      suggestion = find_suggestion
      InternshipSuggestionGenerator.regenerate!(suggestion:, requested_by: Current.user)
      audit("recruitment_internship_suggestion_regenerated", suggestion: suggestion.kind)
      redirect_to recruitment_organization_internship_program_path(@organization, @program),
                  notice: t("flash.recruitment_internship_suggestion_regenerated")
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_organization_internship_program_path(@organization, @program),
                  alert: t("flash.recruitment_internship_suggestion_unavailable")
    end

    private
      def suggestion_params
        params.expect(recruitment_internship_program_suggestion: [ :content ])
      end

      def load_author_program
        load_program
        raise ActiveRecord::RecordNotFound unless @program.editable?
      end

      def load_reviewable_program
        load_program
        raise ActiveRecord::RecordNotFound if @program.closed? || @program.archived?
      end

      def load_program
        @organization = Organization.active.find(params[:organization_id])
        allowed = Current.user.admin? || @organization.memberships.active.exists?(user_id: Current.user.id,
                                                                                    role: InternshipProgram::AUTHOR_ROLES)
        raise ActiveRecord::RecordNotFound unless allowed

        @program = @organization.internship_programs.find(params[:internship_program_id] || params[:id])
      end

      def find_suggestion
        @program.suggestions.find(params[:id])
      end

      def review_suggestion(action)
        load_reviewable_program
        suggestion = find_suggestion
        yield
        audit("recruitment_internship_suggestion_#{action}", suggestion: suggestion.kind)
        redirect_to recruitment_organization_internship_program_path(@organization, @program),
                    notice: t("flash.recruitment_internship_suggestion_#{action}")
      rescue ActiveRecord::RecordInvalid
        redirect_to recruitment_organization_internship_program_path(@organization, @program),
                    alert: t("flash.recruitment_internship_suggestion_unavailable")
      end

      def audit(action, **params)
        AuditEvent.record(action, organization: @organization.name, program: @program.name, **params)
      end
  end
end
