# Who at the university is watching an internship. An administrator grants the
# assignment and an administrator takes it away, so there is one place to look
# for who could read a student's internship — ADR-0041 decision 2.
class InternshipFacultyAssignmentsController < ApplicationController
  allow_only :admin

  def create
    placement = InternshipPlacement.find(params[:id])
    placement.faculty_assignments.create!(faculty: eligible_faculty.find(params[:faculty_id]),
                                          assigned_by: Current.user)
    Notification.notify(placement.student, "internship_faculty_assigned",
                        id: placement.id, organization: placement.organization.name)

    redirect_to internship_placement_path(placement), notice: t("flash.internship_faculty_assigned")
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_to internship_placement_path(placement), alert: t("flash.internship_faculty_unavailable")
  rescue ActiveRecord::RecordNotFound
    redirect_to internship_placement_path(placement), alert: t("flash.internship_faculty_ineligible")
  end

  def destroy
    placement = InternshipPlacement.find(params[:id])
    placement.faculty_assignments.active.find(params[:assignment_id]).revoke!(actor: Current.user)

    redirect_to internship_placement_path(placement), notice: t("flash.internship_faculty_revoked")
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    redirect_to internship_placement_path(placement), alert: t("flash.internship_faculty_unavailable")
  end

  private
    # Staff accounts, and the model re-checks it: which staff member supervises
    # an internship is the administrator's judgement, but a learner is never one.
    def eligible_faculty
      User.where(role: %w[ instructor admin ]).order(:name)
    end
end
