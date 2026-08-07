module Recruitment
  class InternshipEvaluationsController < ApplicationController
    def create
      load_evaluation_context
      @evaluation = @application.build_evaluation(evaluation_params.merge(evaluator: Current.user, status: "submitted"))
      @evaluation.submit!
      record_evaluation
      redirect_to recruitment_organization_internship_program_path(@organization, @program),
                  notice: t("flash.recruitment_internship_evaluation_submitted")
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_organization_internship_program_path(@organization, @program),
                  alert: t("flash.recruitment_internship_evaluation_unavailable")
    end

    def update
      load_evaluation_context
      @evaluation = @application.evaluation
      raise ActiveRecord::RecordNotFound unless @evaluation

      @evaluation.assign_attributes(evaluation_params)
      @evaluation.submit!
      record_evaluation
      redirect_to recruitment_organization_internship_program_path(@organization, @program),
                  notice: t("flash.recruitment_internship_evaluation_submitted")
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_organization_internship_program_path(@organization, @program),
                  alert: t("flash.recruitment_internship_evaluation_unavailable")
    end

    private
      def evaluation_params
        params.expect(recruitment_internship_evaluation: [ :rating, :learning_outcomes_met, :feedback, :next_steps ])
      end

      def load_evaluation_context
        @organization = Organization.active.find(params[:organization_id])
        @program = @organization.internship_programs.find(params[:internship_program_id])
        @application = @program.applications.find(params[:application_id])
        membership = @organization.memberships.active.find_by(user_id: Current.user.id)
        authorized = Current.user.admin? || (membership && InternshipEvaluation::REVIEWER_ROLES.include?(membership.role) &&
          (membership.role != "mentor" || @program.mentor_id == Current.user.id))
        raise ActiveRecord::RecordNotFound unless authorized && @application.accepted?
      end

      def record_evaluation
        AuditEvent.record("recruitment_internship_evaluation_submitted", organization: @organization.name,
                          program: @program.name, student: @application.student.name)
      end
  end
end
