# The student's side of an internship request. Position-less by design: the
# target is a company that opted in, never a published program.
class InternshipRequestsController < ApplicationController
  allow_only :student

  def index
    @requests = Current.user.internship_requests.includes(:organization).newest_first
    @can_request = Organization.accepting_internship_requests.exists?
    # This screen is the student's door to the whole lifecycle, so an internship
    # that is already running belongs at the top of it: a request that was
    # approved months ago is not what a placed student came here for, and the
    # week's report is the one thing anybody is waiting on them for.
    @placements = Current.user.internship_placements.open_placements.includes(:organization).newest_first
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
        # The slug, not the row id: an organization is addressed by name in
        # every URL now, and a notification's action path is a URL it has to
        # still be able to build months later. The slug is set once at creation
        # and nothing rewrites it.
        Notification.notify(membership.user, "internship_request_received",
                            organization_slug: internship_request.organization.slug,
                            organization: internship_request.organization.name,
                            student: Current.user.name)
      end
    end
end
