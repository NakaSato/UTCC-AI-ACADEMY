module Recruitment
  class OrganizationsController < ApplicationController
    allow_only :admin, only: %i[ new create create_membership revoke_membership ]

    def index
      @organizations = if Current.user.admin?
        Organization.order(:name)
      else
        Current.user.organizations.merge(Organization.active).order(:name)
      end
    end

    def new
      @organization = Organization.new
      @users = eligible_users
    end

    def create
      owner = eligible_users.find(organization_params[:owner_id])
      @organization = Organization.new(organization_params.except(:owner_id))
      @organization.creator = Current.user

      Organization.transaction do
        @organization.save!
        @organization.memberships.create!(user: owner, role: "owner")
        AuditEvent.record("recruitment_organization_created", name: @organization.name,
                          slug: @organization.slug)
        AuditEvent.record("recruitment_membership_granted", organization: @organization.name,
                          member: owner.name, role: "owner")
      end

      redirect_to recruitment_organization_path(@organization),
                  notice: t("flash.recruitment_organization_created", name: @organization.name)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => error
      @users = eligible_users
      @organization ||= Organization.new
      @organization.errors.add(:base, error.record.errors.full_messages.to_sentence) if error.respond_to?(:record)
      render :new, status: :unprocessable_entity
    end

    def show
      @organization = find_visible_organization
      @memberships = @organization.memberships.active.includes(:user).order(:role, :id)
      @users = eligible_users
      @can_manage_invitations = can_manage_invitations?
      @can_view_reporting = Current.user.admin? || @organization.memberships.active.exists?(user_id: Current.user.id,
                                                                                             role: Recruitment::OrganizationReporting::REPORTER_ROLES)
      @invitees = eligible_invitees(@organization)
      @pending_invitations = @organization.invitations.pending.includes(:invitee).order(:expires_at, :id)
    end

    def create_membership
      organization = Organization.find(params[:id])
      user = eligible_users.find(membership_params[:user_id])
      membership = organization.memberships.create!(user:, role: membership_params[:role])
      AuditEvent.record("recruitment_membership_granted", organization: organization.name,
                        member: user.name, role: membership.role)

      redirect_to recruitment_organization_path(organization),
                  notice: t("flash.recruitment_membership_granted", name: user.name)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => error
      organization = Organization.find(params[:id])
      alert = error.respond_to?(:record) ? error.record.errors.full_messages.to_sentence : t("flash.recruitment_member_missing")
      redirect_to recruitment_organization_path(organization), alert:
    end

    def revoke_membership
      organization = Organization.find(params[:id])
      membership = organization.memberships.find_by!(user_id: params[:user_id])
      membership.revoke!
      AuditEvent.record("recruitment_membership_revoked", organization: organization.name,
                        member: membership.user.name, role: membership.role)

      redirect_to recruitment_organization_path(organization),
                  notice: t("flash.recruitment_membership_revoked", name: membership.user.name)
    rescue ActiveRecord::RecordInvalid
      redirect_to recruitment_organization_path(organization),
                  alert: t("flash.recruitment_owner_revoke_forbidden")
    rescue ActiveRecord::RecordNotFound
      redirect_to recruitment_organizations_path, alert: t("flash.recruitment_member_missing")
    end

    private
      def organization_params
        params.expect(organization: [ :name, :slug, :owner_id ])
      end

      def membership_params
        params.expect(membership: [ :user_id, :role ])
      end

      def eligible_users
        User.where.not(role: "admin").order(:name)
      end

      def eligible_invitees(organization)
        User.where.not(role: "admin")
            .where.not(id: organization.memberships.active.select(:user_id))
            .where.not(id: organization.invitations.pending.select(:invitee_id))
            .order(:name)
      end

      def can_manage_invitations?
        Current.user.admin? || @organization.memberships.active.exists?(user_id: Current.user.id, role: "owner")
      end

      def find_visible_organization
        organization = Organization.find(params[:id])
        raise ActiveRecord::RecordNotFound unless organization.visible_to?(Current.user)

        organization
      end
  end
end
