module Recruitment
  class ReportingController < ApplicationController
    def show
      @organization = Organization.active.find(params[:id])
      @summary = Recruitment::OrganizationReporting.call(organization: @organization, viewer: Current.user)
      raise ActiveRecord::RecordNotFound unless @summary
    end
  end
end
