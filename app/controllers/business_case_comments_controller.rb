class BusinessCaseCommentsController < ApplicationController
  def create
    business_case = accessible_case
    business_case.comments.create!(author: Current.user, body: comment_params[:body])

    redirect_to business_case_path(business_case), notice: t("flash.business_case_comment_created")
  rescue ActiveRecord::RecordInvalid => error
    redirect_to business_case_path(business_case), alert: error.record.errors.full_messages.to_sentence
  end

  private
    def comment_params
      params.expect(comment: [ :body ])
    end

    def accessible_case
      business_case = BusinessCase.find(params[:id])
      raise ActiveRecord::RecordNotFound unless business_case.accessible_to?(Current.user)

      business_case
    end
end
