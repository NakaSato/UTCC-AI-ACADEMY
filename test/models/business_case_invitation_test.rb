require "test_helper"

class BusinessCaseInvitationTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Invited Case Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @business_case = @organization.business_cases.create!(owner: users(:one), title: "Forecast returns")
    @business_case.transition_to!("published", actor: users(:one))
  end

  test "generates an opaque expiring token that the row cannot reproduce" do
    invitation = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))

    assert_operator invitation.token.length, :>=, 60
    assert_not_equal invitation.token, invitation.token_digest
    assert_equal Digest::SHA256.hexdigest(invitation.token), invitation.token_digest
    assert_nil BusinessCaseInvitation.find(invitation.id).token
    assert_predicate invitation, :pending?
    assert_predicate invitation, :active?
    assert_in_delta 7.days.from_now.to_f, invitation.expires_at.to_f, 2.seconds
  end

  test "only an owner may invite and only a student may be invited" do
    @organization.memberships.create!(user: users(:two), role: "recruiter")

    assert_not @business_case.invitations.build(inviter: users(:two), invitee: users(:student)).valid?
    assert_not @business_case.invitations.build(inviter: users(:instructor), invitee: users(:student)).valid?
    assert_not @business_case.invitations.build(inviter: users(:admin), invitee: users(:student)).valid?
    assert_not @business_case.invitations.build(inviter: users(:one), invitee: users(:instructor)).valid?
    assert_not @business_case.invitations.build(inviter: users(:one), invitee: users(:admin)).valid?
    assert_not @business_case.invitations.build(inviter: users(:one), invitee: users(:one)).valid?
    assert @business_case.invitations.build(inviter: users(:one), invitee: users(:student)).valid?
  end

  test "a draft or closed case issues no invitations" do
    draft = @organization.business_cases.create!(owner: users(:one), title: "Still drafting")

    assert_not draft.invitations.build(inviter: users(:one), invitee: users(:student)).valid?

    @business_case.transition_to!("closed", actor: users(:one))
    assert_not @business_case.invitations.build(inviter: users(:one), invitee: users(:student)).valid?
  end

  test "only one open invitation exists per case and student" do
    @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))
    duplicate = @business_case.invitations.build(inviter: users(:one), invitee: users(:student))

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:invitee], :any?
  end

  test "an expired open invitation is retired so a new one can be issued" do
    expired = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))
    expired.update!(expires_at: 1.minute.ago)

    replacement = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))

    assert_predicate replacement, :active?
    assert_predicate expired.reload.revoked_at, :present?
  end

  test "acceptance is single use and creates the active student participant" do
    invitation = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))

    assert_difference "BusinessCaseParticipant.count", 1 do
      invitation.accept!
    end

    participant = @business_case.participants.find_by(user: users(:student))
    assert_equal "student", participant.role
    assert_predicate participant, :active?
    assert_nil participant.assigned_by_id
    assert_predicate invitation.reload.accepted_at, :present?
    assert_not_predicate invitation, :pending?

    assert_raises(ActiveRecord::RecordInvalid) { invitation.accept! }
    assert_equal 1, @business_case.participants.count
  end

  test "a mismatched user cannot accept an invitation" do
    invitation = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))

    assert_not invitation.acceptable_for?(users(:two))
    assert_not invitation.acceptable_for?(users(:instructor))
    assert_not invitation.acceptable_for?(nil)
    assert invitation.acceptable_for?(users(:student))
  end

  test "an expired or declined invitation grants no access" do
    expired = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))
    expired.update!(expires_at: 1.minute.ago)

    assert_no_difference "BusinessCaseParticipant.count" do
      assert_raises(ActiveRecord::RecordInvalid) { expired.accept! }
    end

    declinable = @business_case.invitations.create!(inviter: users(:one), invitee: users(:two))

    assert_no_difference "BusinessCaseParticipant.count" do
      declinable.decline!
    end

    assert_predicate declinable.reload.declined_at, :present?
    assert_raises(ActiveRecord::RecordInvalid) { declinable.accept! }
    assert_not @business_case.accessible_to?(users(:two))
  end

  test "a revoked participant can be re-invited and reactivated once" do
    invitation = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))
    invitation.accept!
    @business_case.participants.find_by(user: users(:student)).revoke!

    assert_not @business_case.accessible_to?(users(:student))

    reinvitation = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))
    reinvitation.accept!

    assert @business_case.reload.accessible_to?(users(:student))
    assert_equal 1, @business_case.participants.active.count
  end

  test "an active participant cannot be invited again" do
    invitation = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))
    invitation.accept!

    duplicate = @business_case.invitations.build(inviter: users(:one), invitee: users(:student))
    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:invitee], :any?
  end
end
