module Recruitment
  # The company workspace's front door: what is waiting on this company today.
  #
  # Its sibling `OrganizationsController#show` is the company's *record* —
  # members, invitations, links. Two questions, two screens; this one is where
  # `/` lands, because "is anyone waiting on me" is the question a member
  # arrives with. See ADR-0048.
  class CompanyWorkController < ApplicationController
    def show
      @organization = Organization.from_param!(params[:id])
      raise ActiveRecord::RecordNotFound unless @organization.visible_to?(Current.user)

      # Nil for an organization that is not active — there is no work surface
      # for a company that is not operating, the same way its other screens
      # are not there.
      @dashboard = CompanyDashboard.call(organization: @organization, viewer: Current.user)
      raise ActiveRecord::RecordNotFound if @dashboard.nil?
    end
  end
end
