require "test_helper"

class AcademicPostInvitationsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "owner sends an in-app invitation and invitee accepts it" do
    post_record = AcademicPost.create!(owner: users(:one), title: "Shared", body: "Draft")

    assert_difference [ "AcademicPostInvitation.count", "Notification.count" ], 1 do
      post invitations_academic_post_path(post_record), params: {
        invitation: { student_id: users(:two).student_id, permission: "editor" }
      }
    end

    invitation = post_record.invitations.order(:id).last
    assert_equal users(:two), invitation.invitee
    assert_equal "academic_post_invitation", users(:two).notifications.order(:id).last.kind

    sign_out
    sign_in_as users(:two)
    get academic_post_invitation_path(invitation.token)
    assert_response :success
    assert_select "form[action=?]", accept_academic_post_invitation_path(invitation.token)

    post accept_academic_post_invitation_path(invitation.token)

    assert_redirected_to edit_academic_post_path(post_record)
    assert_predicate post_record.reload.memberships.find_by(user: users(:two)), :editor?

    patch academic_post_path(post_record), params: {
      academic_post: { title: "Shared update", body: "Edited by collaborator", lock_version: post_record.reload.lock_version }
    }

    assert_redirected_to academic_post_path(post_record)
    assert_equal "Edited by collaborator", post_record.reload.body
  end

  test "wrong user cannot accept an invitation or read the private post" do
    post_record = AcademicPost.create!(owner: users(:one), title: "Private", body: "Draft")
    invitation = post_record.invitations.create!(inviter: users(:one), invitee: users(:two), permission: :viewer)

    sign_out
    sign_in_as users(:instructor)
    get academic_post_invitation_path(invitation.token)
    assert_response :not_found

    get academic_post_path(post_record)
    assert_response :not_found
  end

  test "owner can revoke an accepted collaborator and editor access is denied" do
    post_record = AcademicPost.create!(owner: users(:one), title: "Shared", body: "Draft")
    membership = post_record.memberships.create!(user: users(:two), permission: :editor)

    assert_difference -> { post_record.reload.memberships.active.count }, -1 do
      delete academic_post_membership_path(post_record, users(:two))
    end
    assert_redirected_to academic_post_path(post_record)

    sign_out
    sign_in_as users(:two)
    get edit_academic_post_path(post_record)
    assert_response :not_found
    assert_not membership.reload.active?
  end

  test "a viewer can read a draft but cannot open its editor" do
    post_record = AcademicPost.create!(owner: users(:one), title: "Read only", body: "Draft")
    post_record.memberships.create!(user: users(:two), permission: :viewer)

    sign_out
    sign_in_as users(:two)
    get academic_post_path(post_record)
    assert_response :success

    get edit_academic_post_path(post_record)
    assert_redirected_to academic_post_path(post_record)
  end

  test "owner cannot create duplicate or self invitations" do
    post_record = AcademicPost.create!(owner: users(:one), title: "Shared", body: "Draft")
    post_record.invitations.create!(inviter: users(:one), invitee: users(:two), permission: :viewer)

    assert_no_difference "AcademicPostInvitation.count" do
      post invitations_academic_post_path(post_record), params: {
        invitation: { student_id: users(:two).student_id, permission: "editor" }
      }
    end
    assert_redirected_to academic_post_path(post_record)
    assert_equal I18n.t("flash.academic_post_invitation_exists"), flash[:alert]

    assert_no_difference "AcademicPostInvitation.count" do
      post invitations_academic_post_path(post_record), params: {
        invitation: { student_id: users(:one).student_id, permission: "viewer" }
      }
    end
    assert_redirected_to academic_post_path(post_record)
  end
end
