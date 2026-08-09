class BusinessCaseMilestonesController < ApplicationController
  def create
    business_case = manageable_case
    milestone = business_case.milestones.create!(milestone_params)
    AuditEvent.record("business_case_milestone_created", organization: business_case.organization.name,
                      title: business_case.title, milestone: milestone.title)

    redirect_to business_case_path(business_case), notice: t("flash.business_case_milestone_created")
  rescue ActiveRecord::RecordInvalid => error
    redirect_to business_case_path(business_case), alert: error.record.errors.full_messages.to_sentence
  end

  def complete
    business_case = manageable_case
    milestone = business_case.milestones.find(params[:milestone_id])
    milestone.complete!
    AuditEvent.record("business_case_milestone_completed", organization: business_case.organization.name,
                      title: business_case.title, milestone: milestone.title)

    redirect_to business_case_path(business_case), notice: t("flash.business_case_milestone_completed")
  rescue ActiveRecord::RecordInvalid
    redirect_to business_case_path(business_case), alert: t("flash.business_case_milestone_invalid")
  end

  private
    def milestone_params
      params.expect(milestone: [ :title, :description ])
    end

    def manageable_case
      business_case = BusinessCase.find(params[:id])
      raise ActiveRecord::RecordNotFound unless business_case.manageable_by?(Current.user)

      business_case
    end
end
