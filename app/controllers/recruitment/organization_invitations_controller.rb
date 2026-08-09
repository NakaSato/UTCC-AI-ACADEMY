module Recruitment
  class OrganizationInvitationsController < ApplicationController
    def create
      organization = managed_organization
      invitee = eligible_users.find(invitation_params[:user_id])
      invitation = organization.invitations.create!(
        inviter: Current.user,
        invitee:,
        role: invitation_params[:role]
      )
      Notification.notify(
        invitee,
        "recruitment_organization_invitation",
        token: invitation.token,
        organization: organization.name,
        role: invitation.role
      )
      AuditEvent.record("recruitment_invitation_created", organization: organization.name,
                        member: invitee.name, role: invitation.role)

      redirect_to company_path(organization),
                  notice: t("flash.recruitment_invitation_sent", name: invitee.name)
    rescue ActiveRecord::RecordInvalid => error
      alert = if error.respond_to?(:record)
        error.record.errors.full_messages.to_sentence
      else
        t("flash.recruitment_invitee_missing")
      end
      redirect_to company_path(organization), alert:
    end

    def show
      @invitation = invitation_for_current_user
      @token = params[:token]
    end

    def accept
      invitation = invitation_for_current_user
      invitation.accept!
      AuditEvent.record("recruitment_invitation_accepted", organization: invitation.organization.name,
                        member: Current.user.name, role: invitation.role)
      redirect_to company_path(invitation.organization),
                  notice: t("flash.recruitment_invitation_accepted")
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_organization_invitation_path(params[:token]),
                  alert: t("flash.recruitment_invitation_unavailable")
    end

    def decline
      invitation = invitation_for_current_user
      invitation.decline!
      AuditEvent.record("recruitment_invitation_declined", organization: invitation.organization.name,
                        member: Current.user.name, role: invitation.role)
      redirect_to companies_path,
                  notice: t("flash.recruitment_invitation_declined")
    rescue ActiveRecord::RecordInvalid
      redirect_to companies_path,
                  alert: t("flash.recruitment_invitation_unavailable")
    end

    private
      def invitation_params
        params.expect(invitation: [ :user_id, :role ])
      end

      def eligible_users
        User.where.not(role: "admin").order(:name)
      end

      def managed_organization
        organization = Organization.active.from_param!(params[:id])
        return organization if Current.user.admin?
        return organization if organization.memberships.active.exists?(user_id: Current.user.id, role: "owner")

        raise ActiveRecord::RecordNotFound
      end

      def invitation_for_current_user
        token_digest = Digest::SHA256.hexdigest(params[:token].to_s)
        invitation = OrganizationInvitation.find_by!(token_digest:, invitee_id: Current.user.id)
        raise ActiveRecord::RecordNotFound unless invitation.acceptable_for?(Current.user)

        invitation
      end
  end
end
