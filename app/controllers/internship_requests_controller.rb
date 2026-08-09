# The student's side of an internship request. Position-less by design: the
# target is a company that opted in, never a published program.
class InternshipRequestsController < ApplicationController
  allow_only :student

  def index
    @requests = Current.user.internship_requests.includes(:organization).newest_first
    @can_request = Organization.accepting_internship_requests.exists?
  end

  def new
    @internship_request = InternshipRequest.new(organization: targetable_organizations.first)
    @organizations = targetable_organizations
    raise ActiveRecord::RecordNotFound if @organizations.empty?
  end

  def create
    organization = targetable_organizations.find(internship_request_params[:organization_id])
    @internship_request = organization.internship_requests.new(
      internship_request_params.except(:organization_id).merge(student: Current.user)
    )
    @internship_request.save!

    redirect_to internship_request_path(@internship_request), notice: t("flash.internship_request_created")
  rescue ActiveRecord::RecordInvalid
    # A company that never opted in is a RecordNotFound from the finder above and
    # is deliberately not rescued: it fails closed rather than re-rendering.
    @organizations = targetable_organizations
    render :new, status: :unprocessable_entity
  end

  def show
    @internship_request = own_request
  end

  def edit
    @internship_request = own_request
    return if @internship_request.editable_by_student?

    redirect_to internship_request_path(@internship_request), alert: t("flash.internship_request_not_editable")
  end

  def update
    @internship_request = own_request
    unless @internship_request.editable_by_student?
      return redirect_to internship_request_path(@internship_request),
                         alert: t("flash.internship_request_not_editable")
    end

    @internship_request.update!(internship_request_params.except(:organization_id))
    redirect_to internship_request_path(@internship_request), notice: t("flash.internship_request_updated")
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  def submit
    @internship_request = own_request
    @internship_request.submit!(actor: Current.user)
    notify_deciders(@internship_request)
    AuditEvent.record("internship_request_submitted", organization: @internship_request.organization.name)

    redirect_to internship_request_path(@internship_request), notice: t("flash.internship_request_submitted")
  rescue ActiveRecord::RecordInvalid
    redirect_to internship_request_path(@internship_request), alert: t("flash.internship_request_unavailable")
  end

  def withdraw
    @internship_request = own_request
    @internship_request.withdraw!(actor: Current.user)
    AuditEvent.record("internship_request_withdrawn", organization: @internship_request.organization.name)

    redirect_to internship_request_path(@internship_request), notice: t("flash.internship_request_withdrawn")
  rescue ActiveRecord::RecordInvalid
    redirect_to internship_request_path(@internship_request), alert: t("flash.internship_request_unavailable")
  end

  private
    def internship_request_params
      params.expect(internship_request: [ :organization_id, :motivation, :learning_goals ])
    end

    def targetable_organizations
      Organization.accepting_internship_requests.order(:name)
    end

    def own_request
      Current.user.internship_requests.find(params[:id])
    end

    def notify_deciders(internship_request)
      internship_request.organization.memberships.active
                       .where(role: InternshipRequest::DECIDER_ROLES).includes(:user).find_each do |membership|
        Notification.notify(membership.user, "internship_request_received",
                            organization_id: internship_request.organization_id,
                            organization: internship_request.organization.name,
                            student: Current.user.name)
      end
    end
end
