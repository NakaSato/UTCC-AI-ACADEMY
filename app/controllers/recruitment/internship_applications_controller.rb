module Recruitment
  class InternshipApplicationsController < ApplicationController
    def index
      load_reviewable_program
      @applications = @program.applications.includes(:student, :evaluation).newest_first
    end

    def create
      @program = InternshipProgram.published_for_candidates.find(params[:id])
      raise ActiveRecord::RecordNotFound unless Current.user&.student?

      @application = @program.apply!(student: Current.user, statement: application_params[:statement])
      AuditEvent.record("recruitment_internship_application_created", organization: @program.organization.name,
                        program: @program.name, student: Current.user.name)
      redirect_to recruitment_internship_path(@program), notice: t("flash.recruitment_internship_application_created")
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_internship_path(@program), alert: t("flash.recruitment_internship_application_unavailable")
    end

    def accept
      review_application { @application.accept!(reviewer: Current.user) }
    end

    def reject
      review_application { @application.reject!(reviewer: Current.user) }
    end

    def withdraw
      @application = Current.user.internship_applications.find(params[:id])
      @application.withdraw!
      AuditEvent.record("recruitment_internship_application_withdrawn", organization: @application.program.organization.name,
                        program: @application.program.name)
      redirect_to recruitment_internship_path(@application.program), notice: t("flash.recruitment_internship_application_withdrawn")
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_internship_path(@application.program), alert: t("flash.recruitment_internship_application_unavailable")
    end

    private
      def application_params
        params.expect(recruitment_internship_application: [ :statement ])
      end

      def load_reviewable_program
        @organization = Organization.active.from_param!(params[:company_id])
        permitted = Current.user.admin? || @organization.memberships.active.exists?(user_id: Current.user.id,
                                                                                      role: InternshipProgram::REVIEWER_ROLES)
        raise ActiveRecord::RecordNotFound unless permitted

        @program = @organization.internship_programs.find(params[:internship_program_id])
        raise ActiveRecord::RecordNotFound if @program.archived?
      end

      def review_application
        load_reviewable_program
        @application = @program.applications.find(params[:id])
        yield
        action = @application.accepted? ? "accepted" : "rejected"
        AuditEvent.record("recruitment_internship_application_#{action}", organization: @organization.name,
                          program: @program.name, student: @application.student.name)
        redirect_to company_internship_program_path(@organization, @program),
                    notice: t("flash.recruitment_internship_application_#{action}")
      rescue ActiveRecord::RecordInvalid
        redirect_to company_internship_program_path(@organization, @program),
                    alert: t("flash.recruitment_internship_application_unavailable")
      end
  end
end
