# Placements are visible to the placed student and to the company's deciders;
# the lifecycle belongs to the company alone.
class InternshipPlacementsController < ApplicationController
  def index
    @student_placements = Current.user.internship_placements.includes(:organization).newest_first
    @company_placements = InternshipPlacement.joins(organization: :memberships)
                                             .merge(Organization.active)
                                             .where(organization_memberships: {
                                                      user_id: Current.user.id, status: "active",
                                                      role: InternshipPlacement::DECIDER_ROLES
                                                    })
                                             .includes(:organization, :student)
                                             .newest_first
    @placeable_requests = placeable_requests
    @placeable_applications = placeable_applications
  end

  def show
    @placement = visible_placement
    @manageable = @placement.manageable_by?(Current.user)
    @is_student = @placement.student_id == Current.user.id
    @reports = @placement.progress_reports.newest_first.includes(:acknowledged_by)
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
                                       .where.not(id: InternshipPlacement.select(:application_id))
                                       .includes(:student, program: :organization)
    end

    def visible_placement
      placement = InternshipPlacement.find(params[:id])
      raise ActiveRecord::RecordNotFound unless placement.visible_to?(Current.user)

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
                          outcome: t("internship_placements.status.#{placement.status}"))

      redirect_to internship_placement_path(placement), notice:
    rescue ActiveRecord::RecordInvalid
      redirect_to internship_placement_path(placement), alert: t("flash.internship_placement_unavailable")
    end
end
