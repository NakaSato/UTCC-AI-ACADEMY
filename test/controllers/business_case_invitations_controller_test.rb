require "test_helper"

class BusinessCaseInvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Case Invitation Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @business_case = @organization.business_cases.create!(owner: users(:one), title: "Loyalty programme")
    @business_case.transition_to!("published", actor: users(:one))
  end

  test "an owner invites a student who accepts through the in-app notification" do
    sign_in_as users(:one)

    assert_difference [ "BusinessCaseInvitation.count", "Notification.count", "AuditEvent.count" ], 1 do
      post invitations_business_case_path(@business_case), params: { invitation: { user_id: users(:student).id } }
    end

    invitation = @business_case.invitations.order(:id).last
    notification = users(:student).notifications.order(:id).last
    token = notification.params.fetch("token")

    assert_redirected_to business_case_path(@business_case)
    assert_equal "business_case_invitation", notification.kind
    assert_equal business_case_invitation_path(token), notification.action_path
    assert_equal Digest::SHA256.hexdigest(token), invitation.token_digest
    assert_predicate notification.text, :present?

    audit = AuditEvent.where(action: "business_case_invitation_created").order(:id).last
    assert_equal users(:student).name, audit.params["member"]
    assert_not audit.params.value?(token), "an audit row must never carry the invitation token"

    sign_out
    sign_in_as users(:student)
    get business_case_invitation_path(token)
    assert_response :success
    assert_select "form[action=?]", accept_business_case_invitation_path(token)

    assert_difference "BusinessCaseParticipant.count", 1 do
      post accept_business_case_invitation_path(token)
    end

    assert_redirected_to business_case_path(@business_case)
    assert_equal "student", @business_case.participants.find_by(user: users(:student)).role

    get business_case_path(@business_case)
    assert_response :success
  end

  test "a replayed invitation cannot grant access twice" do
    invitation = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))
    token = invitation.token

    sign_in_as users(:student)
    post accept_business_case_invitation_path(token)
    assert_redirected_to business_case_path(@business_case)

    assert_no_difference "BusinessCaseParticipant.count" do
      post accept_business_case_invitation_path(token)
    end
    assert_response :not_found
  end

  test "a wrong user cannot read or accept an invitation" do
    invitation = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))

    [ users(:two), users(:instructor), users(:admin) ].each do |user|
      sign_in_as user

      get business_case_invitation_path(invitation.token)
      assert_response :not_found, "#{user.name} must not read another student's invitation"

      assert_no_difference "BusinessCaseParticipant.count" do
        post accept_business_case_invitation_path(invitation.token)
      end
      assert_response :not_found

      sign_out
    end
  end

  test "an expired invitation grants no access" do
    invitation = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))
    token = invitation.token
    invitation.update!(expires_at: 1.minute.ago)

    sign_in_as users(:student)
    get business_case_invitation_path(token)
    assert_response :not_found

    assert_no_difference "BusinessCaseParticipant.count" do
      post accept_business_case_invitation_path(token)
    end
    assert_response :not_found
  end

  test "declining creates no access and records the decision" do
    invitation = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))

    sign_in_as users(:student)

    assert_no_difference "BusinessCaseParticipant.count" do
      assert_difference "AuditEvent.count", 1 do
        post decline_business_case_invitation_path(invitation.token)
      end
    end

    assert_redirected_to root_path
    assert_predicate invitation.reload.declined_at, :present?
    assert_not @business_case.accessible_to?(users(:student))

    get business_case_path(@business_case)
    assert_response :not_found
  end

  test "only an active owner can send a case invitation" do
    [ users(:two), users(:student), users(:instructor), users(:admin) ].each do |user|
      sign_in_as user

      assert_no_difference "BusinessCaseInvitation.count" do
        post invitations_business_case_path(@business_case), params: { invitation: { user_id: users(:student).id } }
      end
      assert_response :not_found, "#{user.name} must not invite students to the case"

      sign_out
    end
  end

  test "a non-student cannot be invited to a case" do
    sign_in_as users(:one)

    [ users(:instructor), users(:admin) ].each do |user|
      assert_no_difference "BusinessCaseInvitation.count" do
        post invitations_business_case_path(@business_case), params: { invitation: { user_id: user.id } }
      end
      assert_response :not_found
    end
  end
end
