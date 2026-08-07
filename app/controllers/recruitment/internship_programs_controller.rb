module Recruitment
  class InternshipProgramsController < ApplicationController
    def index
      if params[:organization_id]
        @organization = readable_organization
        @programs = @organization.internship_programs.order(updated_at: :desc, id: :desc)
        @public = false
        @can_create = author_member?
      else
        @programs = InternshipProgram.published_for_candidates.includes(:organization, :mentor)
                                      .order(published_at: :desc, id: :desc)
        @public = true
      end
    end

    def new
      @organization = authoring_organization
      @program = @organization.internship_programs.new
      @mentors = available_mentors
    end

    def create
      @organization = authoring_organization
      @program = @organization.internship_programs.new(program_params)
      @program.creator = Current.user
      @program.save!
      audit("recruitment_internship_program_created", program: program_name)
      redirect_to recruitment_organization_internship_program_path(@organization, @program),
                  notice: t("flash.recruitment_internship_program_created")
    rescue ActiveRecord::RecordInvalid
      @mentors = available_mentors
      render :new, status: :unprocessable_entity
    end

    def show
      if params[:organization_id]
        @organization = readable_organization
        @program = @organization.internship_programs.find(params[:id])
        @public = false
        assign_permissions
        @applications = @program.applications.includes(:student, :evaluation).newest_first
        @suggestions = @program.suggestions.newest_first
      else
        @program = InternshipProgram.published_for_candidates.find(params[:id])
        @organization = @program.organization
        @public = true
        @application = Current.user&.student? ? @program.applications.find_by(student_id: Current.user.id) : nil
        @internship_assistant = Recruitment::InternshipApplicationAssistant.call(application: @application,
                                                                                  viewer: Current.user) if @application
      end
    end

    def edit
      load_editable_program
      @mentors = available_mentors
    end

    def update
      return unless load_editable_program

      @program.assign_attributes(program_params)
      @program.save!
      audit("recruitment_internship_program_updated", program: program_name)
      redirect_to recruitment_organization_internship_program_path(@organization, @program),
                  notice: t("flash.recruitment_internship_program_saved")
    rescue ActiveRecord::StaleObjectError
      @program = @organization.internship_programs.find(@program.id)
      @conflict = true
      @mentors = available_mentors
      render :edit, status: :conflict
    rescue ActiveRecord::RecordInvalid
      @mentors = available_mentors
      render :edit, status: :unprocessable_entity
    end

    def submit
      transition_program("review", InternshipProgram::AUTHOR_ROLES, "submitted")
    end

    def request_changes
      transition_program("draft", %w[ owner hiring_manager ], "changes_requested")
    end

    def publish
      transition_program("published", %w[ owner hiring_manager ], "published")
    end

    def pause
      transition_program("paused", %w[ owner hiring_manager ], "paused")
    end

    def close
      transition_program("closed", %w[ owner hiring_manager ], "closed")
    end

    def archive
      transition_program("archived", %w[ owner hiring_manager ], "archived")
    end

    private
      def program_params
        params.expect(recruitment_internship_program: [
          :name, :department, :description, :duration_weeks, :max_students, :mentor_id,
          :required_skills, :learning_outcomes, :working_days, :remote_policy, :paid,
          :certificate_policy, :equipment_provided, :lock_version
        ])
      end

      def readable_organization
        organization = Organization.active.find(params[:organization_id])
        return organization if Current.user.admin? || organization.member?(Current.user)

        raise ActiveRecord::RecordNotFound
      end

      def authoring_organization
        authorizing_organization(InternshipProgram::AUTHOR_ROLES)
      end

      def authorizing_organization(roles)
        organization = Organization.active.find(params[:organization_id])
        return organization if Current.user.admin?
        return organization if organization.memberships.active.exists?(user_id: Current.user.id, role: roles)

        raise ActiveRecord::RecordNotFound
      end

      def author_member?
        Current.user.admin? || @organization.memberships.active.exists?(user_id: Current.user.id,
                                                                         role: InternshipProgram::AUTHOR_ROLES)
      end

      def available_mentors
        @organization.memberships.active.where(role: %w[ owner hiring_manager mentor ]).includes(:user).map(&:user)
      end

      def load_editable_program
        @organization = authoring_organization
        @program = @organization.internship_programs.find(params[:id])
        return true if @program.editable?

        redirect_to recruitment_organization_internship_program_path(@organization, @program),
                    alert: t("flash.recruitment_internship_program_not_editable")
        false
      end

      def assign_permissions
        author = author_member?
        reviewer = Current.user.admin? || @organization.memberships.active.exists?(user_id: Current.user.id,
                                                                                    role: InternshipProgram::REVIEWER_ROLES)
        approver = Current.user.admin? || @organization.memberships.active.exists?(user_id: Current.user.id,
                                                                                    role: %w[ owner hiring_manager ])
        @can_edit = author && @program.editable?
        @can_submit = author && @program.draft?
        @can_request_changes = approver && @program.review?
        @can_publish = approver && @program.review?
        @can_pause = approver && @program.published?
        @can_close = approver && [ "published", "paused" ].include?(@program.status)
        @can_archive = approver && [ "draft", "review", "paused", "closed" ].include?(@program.status)
        @can_review_applications = reviewer && !@program.archived? && !@program.closed?
        @can_review_suggestions = author && !@program.archived?
        @can_generate_suggestions = @can_review_suggestions && @program.editable?
      end

      def transition_program(target, roles, audit_suffix)
        @organization = authorizing_organization(roles)
        @program = @organization.internship_programs.find(params[:id])
        previous_status = @program.status
        @program.transition_to!(target)
        audit("recruitment_internship_program_#{audit_suffix}", program: program_name,
              from_status: previous_status, to_status: @program.status)
        redirect_to recruitment_organization_internship_program_path(@organization, @program),
                    notice: t("flash.recruitment_internship_program_#{audit_suffix}")
      rescue ActiveRecord::RecordInvalid
        redirect_to recruitment_organization_internship_program_path(@organization, @program),
                    alert: t("flash.recruitment_internship_program_transition_forbidden")
      end

      def program_name = @program.name.presence || t("recruitment.internships.untitled")

      def audit(action, **params)
        AuditEvent.record(action, organization: @organization.name, **params)
      end
  end
end
