# The opt-in switch. A company is targetable by unsolicited student requests
# only while this is on, which is the consent ADR-0041 recorded decision 3
# requires — so it sits with the accountable roles, not everyone who reviews.
class OrganizationInternshipSettingsController < ApplicationController
  def update
    organization = manageable_organization
    accepting = ActiveModel::Type::Boolean.new.cast(params[:accepts_internship_requests])
    organization.update!(accepts_internship_requests: accepting)
    AuditEvent.record(accepting ? "internship_requests_opened" : "internship_requests_closed",
                      organization: organization.name)

    redirect_to organization_internship_requests_path(organization),
                notice: t(accepting ? "flash.internship_requests_opened" : "flash.internship_requests_closed")
  end

  private
    def manageable_organization
      organization = Organization.active.find(params[:organization_id])
      raise ActiveRecord::RecordNotFound unless organization.memberships.active
                                                            .exists?(user_id: Current.user.id,
                                                                     role: InternshipRequest::SETTING_ROLES)

      organization
    end
end
