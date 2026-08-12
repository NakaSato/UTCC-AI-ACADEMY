# Placements are visible to the placed student and to the company's deciders;
# the lifecycle belongs to the company alone.
class InternshipPlacementsController < ApplicationController
  def index
    @student_placements = Current.user.internship_placements.includes(:organization).newest_first
    @weeks_reported = reported_weeks_by_placement
    @company_placements = InternshipPlacement.joins(organization: :memberships)
                                             .merge(Organization.active)
                                             .where(organization_memberships: {
                                                      user_id: Current.user.id, status: "active",
                                                      role: InternshipPlacement::DECIDER_ROLES
                                                    })
                                             .includes(:organization, :student)
                                             .newest_first
    # What this account supervises for the university. Assigned placements only:
    # the assignment is the consent and therefore the boundary, so a staff
    # member sees no internship they were not given — ADR-0041 decision 7.
    @supervised_placements = InternshipPlacement.joins(:faculty_assignments)
                                                .where(internship_faculty_assignments: {
                                                         faculty_id: Current.user.id, status: "active"
                                                       })
                                                .includes(:organization, :student)
                                                .newest_first
    # An administrator supervises nothing and hosts nothing, so every list above
    # is empty for them — and assigning a supervisor happens on a placement they
    # would have had no way to reach. This is that way. It carries the same
    # reach `administrable_by?` grants: the record, never a weekly report.
    @administered_placements = if Current.user.admin?
      InternshipPlacement.includes(:organization, :student, faculty_assignments: :faculty).newest_first
    else
      InternshipPlacement.none
    end
    @placeable_requests = placeable_requests
    @placeable_applications = placeable_applications
  end

  def show
    @placement = visible_placement
    @manageable = @placement.manageable_by?(Current.user)
    @is_student = @placement.student_id == Current.user.id
    @supervising = @placement.supervised_by?(Current.user)
    @assignment = @placement.faculty_assignments.active.includes(:faculty).first
    # Only an administrator assigns, so only an administrator is offered the
    # list of who could be assigned — see ADR-0041 decision 2.
    @assignable_faculty = User.where(role: %w[ instructor admin ]).order(:name) if Current.user.admin?
    # An administrator opens this page to assign a supervisor, not to read a
    # student's weeks. The rows are not loaded for them at all, so there is
    # nothing for a template change to leak later.
    @reads_reports = @placement.visible_to?(Current.user)
    @reports = @reads_reports ? @placement.progress_reports.newest_first
                                          .includes(:acknowledged_by, :faculty_acknowledged_by) : []
    # A deliverable's reader is re-derived per file rather than per screen: the
    # student always, the hosting company while the placement is open, and the
    # faculty supervisor deliberately not — ADR-0041 decision 5.
    @deliverables = @placement.deliverables.newest_first.with_attached_file
                              .select { it.readable_by?(Current.user) }
  end

  # One entry point, two origins: an approved request or an accepted recruitment
  # application. Which one is decided by the parameters, never by guessing.
  def create
    @placement = if params[:internship_request_id].present?
      InternshipPlacement.from_request!(InternshipRequest.find(params[:internship_request_id]), actor: Current.user)
    else
      InternshipPlacement.from_application!(
        Recruitment::InternshipApplication.find(params[:application_id]), actor: Current.user
      )
    end
    AuditEvent.record("internship_placement_created", organization: @placement.organization.name,
                      student: @placement.student.name)

    redirect_to internship_placement_path(@placement), notice: t("flash.internship_placement_created")
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_back fallback_location: internship_placements_path,
                  alert: t("flash.internship_placement_unavailable")
  end

  def activate
    advance_with("internship_placement_activated", t("flash.internship_placement_activated")) do |placement|
      placement.activate!(actor: Current.user)
    end
  end

  def complete
    advance_with("internship_placement_completed", t("flash.internship_placement_completed")) do |placement|
      placement.complete!(actor: Current.user)
    end
  end

  def cancel
    advance_with("internship_placement_cancelled", t("flash.internship_placement_cancelled")) do |placement|
      placement.cancel!(actor: Current.user, reason: params[:cancellation_reason])
    end
  end

  private
    # One query for the whole index instead of one per placement, so the view can
    # answer "did this week get reported?" without touching the database again.
    def reported_weeks_by_placement
      InternshipProgressReport.where(week_starting_on: Date.current.beginning_of_week)
                             .pluck(:internship_placement_id)
                             .to_set
    end

    def decidable_organization_ids
      OrganizationMembership.active
                           .where(user_id: Current.user.id, role: InternshipPlacement::DECIDER_ROLES)
                           .joins(:organization).merge(Organization.active)
                           .select(:organization_id)
    end

    # Approved requests and accepted applications that have not become a
    # placement yet — the only two things a placement may be created from.
    def placeable_requests
      InternshipRequest.where(organization_id: decidable_organization_ids, status: "approved")
                       .where.missing(:placement)
                       .includes(:organization, :student)
                       .newest_first
    end

    def placeable_applications
      Recruitment::InternshipApplication.where(status: "accepted")
                                       .joins(:program)
                                       .where(recruitment_internship_programs: {
                                                organization_id: decidable_organization_ids
                                              })
                                       .where.not(id: InternshipPlacement.where.not(application_id: nil)
                                                                        .select(:application_id))
                                       .includes(:student, program: :organization)
    end

    # An administrator gets in because assigning the supervisor happens here and
    # nowhere else — but on the narrower ticket: see `administrable_by?` and the
    # `@reads_reports` split in `show`.
    def visible_placement
      placement = InternshipPlacement.find(params[:id])
      unless placement.visible_to?(Current.user) || placement.administrable_by?(Current.user)
        raise ActiveRecord::RecordNotFound
      end

      placement
    end

    def manageable_placement
      placement = InternshipPlacement.find(params[:id])
      raise ActiveRecord::RecordNotFound unless placement.manageable_by?(Current.user)

      placement
    end

    def advance_with(audit_action, notice)
      placement = manageable_placement
      yield placement
      AuditEvent.record(audit_action, organization: placement.organization.name,
                        student: placement.student.name)
      Notification.notify(placement.student, "internship_placement_updated",
                          id: placement.id, organization: placement.organization.name,
                          outcome: placement.status)

      redirect_to internship_placement_path(placement), notice:
    rescue ActiveRecord::RecordInvalid
      redirect_to internship_placement_path(placement), alert: t("flash.internship_placement_unavailable")
    end
end
