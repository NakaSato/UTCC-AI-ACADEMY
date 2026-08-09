class BusinessCaseSubmissionsController < ApplicationController
  def create
    business_case = participating_case
    milestone = business_case.milestones.find(params[:milestone_id])
    submission = business_case.submissions.create!(milestone:, author: Current.user,
                                                   body: submission_params[:body])
    business_case.organization.memberships.active.where(role: "owner").includes(:user).find_each do |membership|
      Notification.notify(membership.user, "business_case_submission_received",
                          id: business_case.id, business_case: business_case.title,
                          milestone: milestone.title, member: Current.user.name)
    end

    redirect_to business_case_path(business_case),
                notice: t("flash.business_case_submission_created", version: submission.version)
  rescue ActiveRecord::RecordInvalid => error
    redirect_to business_case_path(business_case), alert: error.record.errors.full_messages.to_sentence
  rescue ActiveRecord::RecordNotUnique
    redirect_to business_case_path(business_case), alert: t("flash.business_case_submission_conflict")
  end

  private
    def submission_params
      params.expect(submission: [ :body ])
    end

    # Only an active student participant reaches the submission path at all;
    # the model re-checks the same scope at write time.
    def participating_case
      business_case = BusinessCase.find(params[:id])
      unless business_case.participants.active.exists?(user_id: Current.user.id, role: "student")
        raise ActiveRecord::RecordNotFound
      end

      business_case
    end
end
