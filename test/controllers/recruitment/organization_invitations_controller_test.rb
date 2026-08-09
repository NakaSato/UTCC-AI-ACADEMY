require "test_helper"

class Recruitment::OrganizationInvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Invitation Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    sign_in_as users(:one)
  end

  test "owner sends an in-app invitation and invitee accepts it" do
    assert_difference [ "OrganizationInvitation.count", "Notification.count", "AuditEvent.count" ], 1 do
      post invitations_company_path(@organization), params: {
        invitation: { user_id: users(:two).id, role: "recruiter" }
      }
    end

    invitation = @organization.invitations.order(:id).last
    notification = users(:two).notifications.order(:id).last
    token = notification.params.fetch("token")
    assert_redirected_to company_path(@organization)
    assert_equal "recruitment_organization_invitation", notification.kind
    assert_equal recruitment_organization_invitation_path(token), notification.action_path
    assert_equal Digest::SHA256.hexdigest(token), invitation.token_digest

    sign_out
    sign_in_as users(:two)
    get recruitment_organization_invitation_path(token)
    assert_response :success
    assert_select "form[action=?]", recruitment_accept_organization_invitation_path(token)

    assert_difference "OrganizationMembership.count", 1 do
      post recruitment_accept_organization_invitation_path(token)
    end

    assert_redirected_to company_path(@organization)
    assert_equal "recruiter", @organization.memberships.find_by(user: users(:two)).role
  end

  test "a wrong user cannot read or accept the invitation" do
    invitation = @organization.invitations.create!(inviter: users(:one), invitee: users(:two), role: "mentor")

    sign_out
    sign_in_as users(:instructor)
    get recruitment_organization_invitation_path(invitation.token)
    assert_response :not_found

    assert_no_difference "OrganizationMembership.count" do
      post recruitment_accept_organization_invitation_path(invitation.token)
    end
    assert_response :not_found
  end

  test "owner can decline and a non-owner member cannot create an invitation" do
    invitation = @organization.invitations.create!(inviter: users(:one), invitee: users(:two), role: "mentor")

    sign_out
    sign_in_as users(:two)
    assert_difference "OrganizationInvitation.count", 0 do
      post invitations_company_path(@organization), params: {
        invitation: { user_id: users(:student).id, role: "mentor" }
      }
    end
    assert_response :not_found

    sign_out
    sign_in_as users(:two)
    post recruitment_decline_organization_invitation_path(invitation.token)

    assert_redirected_to companies_path
    assert invitation.reload.declined_at.present?
    assert_not @organization.member?(users(:two))
  end

  test "administrator can create an invitation" do
    sign_out
    sign_in_as users(:admin)

    assert_difference "OrganizationInvitation.count", 1 do
      post invitations_company_path(@organization), params: {
        invitation: { user_id: users(:student).id, role: "hiring_manager" }
      }
    end

    assert_redirected_to company_path(@organization)
  end
end
