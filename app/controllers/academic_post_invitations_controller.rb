class AcademicPostInvitationsController < ApplicationController
  allow_only :student, :instructor

  def create
      post = Current.user.academic_posts.find(params[:academic_post_id] || params[:id])
    return redirect_to post, alert: t("flash.academic_post_not_editable") unless post.draft?

    invitee = User.find_by(student_id: invitation_params[:student_id].to_s.strip)
    unless invitee&.student? || invitee&.instructor?
      return redirect_to post, alert: t("flash.academic_post_invitee_not_found")
    end

    invitation = post.invitations.create!(
      inviter: Current.user,
      invitee:,
      permission: invitation_params[:permission]
    )
    Notification.notify(
      invitee,
      "academic_post_invitation",
      token: invitation.token,
      title: post.title.presence || I18n.t("academic.untitled")
    )

    redirect_to post, notice: t("flash.academic_post_invitation_sent")
  rescue ActiveRecord::RecordInvalid => error
    alert = if error.record.is_a?(AcademicPostInvitation) && error.record.errors.of_kind?(:invitee, :taken)
      t("flash.academic_post_invitation_exists")
    else
      error.record.errors.full_messages.to_sentence
    end
    redirect_to post, alert:
  rescue ActiveRecord::RecordNotUnique
    redirect_to post, alert: t("flash.academic_post_invitation_exists")
  end

  def show
    @invitation = invitation_for_current_user
  end

  def accept
    invitation = invitation_for_current_user
    invitation.accept!
    redirect_to edit_academic_post_path(invitation.academic_post),
                notice: t("flash.academic_post_invitation_accepted")
  rescue ActiveRecord::RecordInvalid
    redirect_to academic_post_invitation_path(params[:token]),
                alert: t("flash.academic_post_invitation_unavailable")
  end

  def revoke
      post = Current.user.academic_posts.find(params[:academic_post_id])
    membership = post.memberships.find_by!(user_id: params[:user_id])
    membership.revoke!
    redirect_to post, notice: t("flash.academic_post_membership_revoked")
  rescue ActiveRecord::RecordNotFound
    redirect_to academic_posts_path, alert: t("flash.academic_post_forbidden")
  end

  private
    def invitation_for_current_user
      invitation = AcademicPostInvitation.find_by!(token_digest: params[:token])
      raise ActiveRecord::RecordNotFound unless invitation.acceptable_for?(Current.user)

      invitation
    end

    def invitation_params
      params.expect(invitation: [ :student_id, :permission ])
    end
end
