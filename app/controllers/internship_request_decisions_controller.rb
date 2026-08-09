# The company's side: the incoming request queue and the one recorded decision.
#
# Approval records a decision and nothing else. The placement that represents
# the internship itself is a later increment, so nothing here may be read as the
# internship having started or finished (ADR-0041 recorded decision 6).
class InternshipRequestDecisionsController < ApplicationController
  def index
    @organization = decidable_organization
    @requests = @organization.internship_requests.includes(:student).newest_first
    @awaiting = @organization.internship_requests.awaiting_company.count
    @can_change_settings = settings_manageable?(@organization)
  end

  def review
    decide_with(:internship_request_review_started, t("flash.internship_request_review_started")) do |request|
      request.start_review!(actor: Current.user)
    end
  end

  def approve
    decide_with(:internship_request_approved, t("flash.internship_request_approved")) do |request|
      request.approve!(actor: Current.user)
    end
  end

  def reject
    decide_with(:internship_request_rejected, t("flash.internship_request_rejected")) do |request|
      request.reject!(actor: Current.user, reason: params[:decision_reason])
    end
  end

  private
    def decidable_organization
      organization = Organization.active.from_param!(params[:company_id])
      raise ActiveRecord::RecordNotFound unless organization.memberships.active
                                                            .exists?(user_id: Current.user.id,
                                                                     role: InternshipRequest::DECIDER_ROLES)

      organization
    end

    def decidable_request
      internship_request = InternshipRequest.find(params[:id])
      raise ActiveRecord::RecordNotFound unless internship_request.decidable_by?(Current.user)

      internship_request
    end

    def settings_manageable?(organization)
      organization.memberships.active.exists?(user_id: Current.user.id, role: InternshipRequest::SETTING_ROLES)
    end

    def decide_with(audit_action, notice)
      internship_request = decidable_request
      yield internship_request
      AuditEvent.record(audit_action.to_s, organization: internship_request.organization.name,
                        student: internship_request.student.name)
      notify_student(internship_request) if internship_request.decided?

      redirect_to company_internship_requests_path(internship_request.organization), notice:
    rescue ActiveRecord::RecordInvalid
      redirect_to company_internship_requests_path(internship_request.organization),
                  alert: t("flash.internship_request_decision_unavailable")
    end

    def notify_student(internship_request)
      Notification.notify(internship_request.student, "internship_request_decided",
                          id: internship_request.id,
                          organization: internship_request.organization.name,
                          outcome: internship_request.status)
    end
end
