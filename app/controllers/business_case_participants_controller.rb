class BusinessCaseParticipantsController < ApplicationController
  # The case is loaded before anything else so an unauthorized request 404s,
  # while a bad participant only fails the action it was asked to do.
  before_action :load_manageable_case

  def create
    mentor = User.where(role: "instructor").find(participant_params[:user_id])
    @business_case.participants.create!(user: mentor, role: "mentor", assigned_by: Current.user)
    AuditEvent.record("business_case_mentor_assigned", organization: @business_case.organization.name,
                      title: @business_case.title, member: mentor.name)

    redirect_to business_case_path(@business_case),
                notice: t("flash.business_case_mentor_assigned", name: mentor.name)
  rescue ActiveRecord::RecordInvalid => error
    redirect_to business_case_path(@business_case), alert: error.record.errors.full_messages.to_sentence
  rescue ActiveRecord::RecordNotFound
    redirect_to business_case_path(@business_case), alert: t("flash.business_case_member_missing")
  end

  def revoke
    participant = @business_case.participants.active.find_by!(user_id: params[:user_id])
    participant.revoke!
    AuditEvent.record("business_case_participant_revoked", organization: @business_case.organization.name,
                      title: @business_case.title, member: participant.user.name)

    redirect_to business_case_path(@business_case),
                notice: t("flash.business_case_participant_revoked", name: participant.user.name)
  rescue ActiveRecord::RecordInvalid => error
    redirect_to business_case_path(@business_case), alert: error.record.errors.full_messages.to_sentence
  rescue ActiveRecord::RecordNotFound
    redirect_to business_case_path(@business_case), alert: t("flash.business_case_member_missing")
  end

  private
    def participant_params
      params.expect(participant: [ :user_id ])
    end

    def load_manageable_case
      @business_case = BusinessCase.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @business_case.manageable_by?(Current.user)
    end
end
