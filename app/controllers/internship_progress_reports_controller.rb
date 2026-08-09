# The student writes the week; a company decider acknowledges it. Neither can
# rewrite the other's part.
class InternshipProgressReportsController < ApplicationController
  def create
    placement = placement_for_student
    placement.progress_reports.create!(report_params)

    redirect_to internship_placement_path(placement), notice: t("flash.internship_progress_report_submitted")
  rescue ActiveRecord::RecordInvalid => error
    redirect_to internship_placement_path(placement), alert: error.record.errors.full_messages.to_sentence
  rescue ActiveRecord::RecordNotUnique
    redirect_to internship_placement_path(placement), alert: t("flash.internship_progress_report_duplicate")
  end

  def acknowledge
    placement = manageable_placement
    report = placement.progress_reports.find(params[:report_id])
    report.acknowledge!(actor: Current.user)
    AuditEvent.record("internship_progress_report_acknowledged", organization: placement.organization.name,
                      student: placement.student.name, week: report.week_starting_on.to_s)
    Notification.notify(placement.student, "internship_progress_report_acknowledged",
                        id: placement.id, organization: placement.organization.name)

    redirect_to internship_placement_path(placement),
                notice: t("flash.internship_progress_report_acknowledged")
  rescue ActiveRecord::RecordInvalid
    redirect_to internship_placement_path(placement), alert: t("flash.internship_progress_report_unavailable")
  end

  private
    def report_params
      params.expect(progress_report: [ :activities, :outcomes, :blockers, :hours ])
    end

    def placement_for_student
      placement = InternshipPlacement.find(params[:id])
      raise ActiveRecord::RecordNotFound unless placement.student_id == Current.user.id

      placement
    end

    def manageable_placement
      placement = InternshipPlacement.find(params[:id])
      raise ActiveRecord::RecordNotFound unless placement.manageable_by?(Current.user)

      placement
    end
end
