class BusinessCasesController < ApplicationController
  def index
    @managed_cases = BusinessCase.joins(organization: :memberships)
                               .merge(Organization.active)
                               .where(organization_memberships: { user_id: Current.user.id,
                                                                  status: "active",
                                                                  role: BusinessCase::MANAGER_ROLES })
                               .includes(:organization)
                               .newest_first
    @participating_cases = BusinessCase.joins(:participants)
                                       .merge(BusinessCaseParticipant.active)
                                       .where(business_case_participants: { user_id: Current.user.id })
                                       .includes(:organization)
                                       .newest_first
    @can_create = OrganizationMembership.active
                                        .where(user_id: Current.user.id, role: BusinessCase::MANAGER_ROLES)
                                        .joins(:organization).merge(Organization.active).exists?
  end

  def new
    @organizations = case_managing_organizations
    @business_case = BusinessCase.new(organization: @organizations.first)
  end

  def create
    organization = case_managing_organizations.find(business_case_params[:organization_id])
    @business_case = organization.business_cases.new(business_case_params.except(:organization_id))
    @business_case.owner = Current.user
    @business_case.save!
    AuditEvent.record("business_case_created", organization: organization.name, title: @business_case.title)

    redirect_to business_case_path(@business_case), notice: t("flash.business_case_created")
  rescue ActiveRecord::RecordInvalid
    @organizations = case_managing_organizations
    render :new, status: :unprocessable_entity
  end

  def show
    @business_case = accessible_case
    @manageable = @business_case.manageable_by?(Current.user)
    @participant = @business_case.participants.active.find_by(user_id: Current.user.id)
    @participants = @business_case.participants.active.includes(:user).order(:role, :id)
    @milestones = @business_case.milestones.ordered
    @submissions = visible_submissions
    @comments = @business_case.comments.oldest_first.includes(:author)
    return unless @manageable

    @pending_invitations = @business_case.invitations.pending.includes(:invitee).order(:expires_at, :id)
    @invitees = eligible_invitees
    @mentor_candidates = eligible_mentors
  end

  def edit
    @business_case = manageable_case
    return if @business_case.editable?

    redirect_to business_case_path(@business_case), alert: t("flash.business_case_closed_rejected")
  end

  def update
    @business_case = manageable_case
    # A closed case is still readable by its owner; only editing is gone, so say
    # so rather than pretending the case does not exist.
    unless @business_case.editable?
      return redirect_to business_case_path(@business_case), alert: t("flash.business_case_closed_rejected")
    end

    @business_case.update!(business_case_params.except(:organization_id))
    AuditEvent.record("business_case_updated", organization: @business_case.organization.name,
                      title: @business_case.title)

    redirect_to business_case_path(@business_case), notice: t("flash.business_case_updated")
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  def publish
    transition_case_to("published", "business_case_published", t("flash.business_case_published"))
  end

  def close
    transition_case_to("closed", "business_case_closed", t("flash.business_case_closed"))
  end

  private
    def business_case_params
      params.expect(business_case: [ :organization_id, :title, :brief, :requirements ])
    end

    # Creating a case needs an organization whose cases this user may run; with
    # none, the screen does not exist for them.
    def case_managing_organizations
      organizations = Organization.active
                                  .joins(:memberships)
                                  .where(organization_memberships: { user_id: Current.user.id, status: "active",
                                                                     role: BusinessCase::MANAGER_ROLES })
                                  .order(:name)
      raise ActiveRecord::RecordNotFound if organizations.empty?

      organizations
    end

    def accessible_case
      business_case = BusinessCase.find(params[:id])
      raise ActiveRecord::RecordNotFound unless business_case.accessible_to?(Current.user)

      business_case
    end

    def manageable_case
      business_case = BusinessCase.find(params[:id])
      raise ActiveRecord::RecordNotFound unless business_case.manageable_by?(Current.user)

      business_case
    end

    def transition_case_to(target, audit_action, notice)
      business_case = manageable_case
      business_case.transition_to!(target, actor: Current.user, lock_version: params[:lock_version])
      AuditEvent.record(audit_action, organization: business_case.organization.name, title: business_case.title)

      redirect_to business_case_path(business_case), notice:
    rescue ActiveRecord::RecordInvalid
      redirect_to business_case_path(business_case), alert: t("flash.business_case_transition_invalid")
    rescue ActiveRecord::StaleObjectError
      redirect_to business_case_path(business_case), alert: t("flash.business_case_conflict")
    end

    # Students see their own evidence; case managers and mentors review everyone's.
    def visible_submissions
      submissions = @business_case.submissions.newest_first.includes(:author, :milestone)
      return submissions if @manageable || @participant&.mentor?

      submissions.where(author_id: Current.user.id)
    end

    def eligible_invitees
      User.where(role: "student")
          .where.not(id: @business_case.participants.active.select(:user_id))
          .where.not(id: @business_case.invitations.pending.select(:invitee_id))
          .order(:name)
    end

    def eligible_mentors
      User.where(role: "instructor")
          .where.not(id: @business_case.participants.active.select(:user_id))
          .order(:name)
    end
end
