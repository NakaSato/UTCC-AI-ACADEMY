require "test_helper"

class OrganizationInvitationTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Recruitment Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
  end

  test "generates an opaque expiring token for a permitted invitee" do
    invitation = @organization.invitations.create!(inviter: users(:one), invitee: users(:two), role: "recruiter")

    assert_match(/\A[0-9a-f]{64}\z/, invitation.token)
    assert_predicate invitation, :pending?
    assert_predicate invitation, :active?
    assert_in_delta 7.days.from_now.to_f, invitation.expires_at.to_f, 2.seconds
  end

  test "rejects admins, self invitations, non-owners, and owners as invitees" do
    admin_invitation = @organization.invitations.new(inviter: users(:one), invitee: users(:admin), role: "mentor")
    assert_not admin_invitation.valid?

    self_invitation = @organization.invitations.new(inviter: users(:one), invitee: users(:one), role: "mentor")
    assert_not self_invitation.valid?

    non_owner = @organization.memberships.create!(user: users(:two), role: "recruiter")
    unauthorized = @organization.invitations.new(inviter: users(:two), invitee: users(:student), role: "mentor")
    assert_not unauthorized.valid?

    owner_invitation = @organization.invitations.new(inviter: users(:one), invitee: users(:two), role: "owner")
    assert_not owner_invitation.valid?
    assert_predicate non_owner, :active?
  end

  test "only one pending invitation exists for an organization and user" do
    @organization.invitations.create!(inviter: users(:one), invitee: users(:two), role: "mentor")
    duplicate = @organization.invitations.new(inviter: users(:one), invitee: users(:two), role: "recruiter")

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:invitee], :any?
  end

  test "accepting creates the invited membership and records a decision" do
    invitation = @organization.invitations.create!(inviter: users(:one), invitee: users(:two), role: "hiring_manager")

    assert_difference "OrganizationMembership.count", 1 do
      invitation.accept!
    end

    assert_not_predicate invitation.reload, :pending?
    assert_equal "hiring_manager", @organization.memberships.find_by(user: users(:two)).role
    assert invitation.accepted_at.present?
  end

  test "declining does not create organization access" do
    invitation = @organization.invitations.create!(inviter: users(:one), invitee: users(:two), role: "mentor")

    assert_no_difference "OrganizationMembership.count" do
      invitation.decline!
    end

    assert invitation.reload.declined_at.present?
    assert_not @organization.member?(users(:two))
  end

  test "expired invitations cannot be accepted" do
    invitation = @organization.invitations.create!(inviter: users(:one), invitee: users(:two), role: "mentor")
    invitation.update!(expires_at: 1.minute.ago)

    assert_raises(ActiveRecord::RecordInvalid) { invitation.accept! }
    assert_not @organization.member?(users(:two))
  end
end
