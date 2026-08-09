class BusinessCaseInvitationsController < ApplicationController
  def create
    business_case = manageable_case
    invitee = User.where(role: "student").find(invitation_params[:user_id])
    invitation = business_case.invitations.create!(inviter: Current.user, invitee:)
    Notification.notify(
      invitee,
      "business_case_invitation",
      token: invitation.token,
      business_case: business_case.title,
      organization: business_case.organization.name
    )
    AuditEvent.record("business_case_invitation_created", organization: business_case.organization.name,
                      title: business_case.title, member: invitee.name)

    redirect_to business_case_path(business_case),
                notice: t("flash.business_case_invitation_sent", name: invitee.name)
  rescue ActiveRecord::RecordInvalid => error
    alert = error.respond_to?(:record) ? error.record.errors.full_messages.to_sentence : t("flash.business_case_invitee_missing")
    redirect_to business_case_path(business_case), alert:
  end

  def show
    @invitation = invitation_for_current_user
    @token = params[:token]
  end

  def accept
    invitation = invitation_for_current_user
    invitation.accept!
    AuditEvent.record("business_case_invitation_accepted", organization: invitation.business_case.organization.name,
                      title: invitation.business_case.title, member: Current.user.name)
    redirect_to business_case_path(invitation.business_case),
                notice: t("flash.business_case_invitation_accepted")
  rescue ActiveRecord::RecordInvalid
    redirect_to business_case_invitation_path(params[:token]),
                alert: t("flash.business_case_invitation_unavailable")
  end

  def decline
    invitation = invitation_for_current_user
    invitation.decline!
    AuditEvent.record("business_case_invitation_declined", organization: invitation.business_case.organization.name,
                      title: invitation.business_case.title, member: Current.user.name)
    redirect_to root_path, notice: t("flash.business_case_invitation_declined")
  rescue ActiveRecord::RecordInvalid
    redirect_to root_path, alert: t("flash.business_case_invitation_unavailable")
  end

  private
    def invitation_params
      params.expect(invitation: [ :user_id ])
    end

    def manageable_case
      business_case = BusinessCase.find(params[:id])
      raise ActiveRecord::RecordNotFound unless business_case.manageable_by?(Current.user)

      business_case
    end

    def invitation_for_current_user
      token_digest = Digest::SHA256.hexdigest(params[:token].to_s)
      invitation = BusinessCaseInvitation.find_by!(token_digest:, invitee_id: Current.user.id)
      raise ActiveRecord::RecordNotFound unless invitation.acceptable_for?(Current.user)

      invitation
    end
end
