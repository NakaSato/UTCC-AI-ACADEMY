require "test_helper"

class AcademicPostPermissionTest < ActiveSupport::TestCase
  test "accepting an editor invitation creates active membership without storing a raw token" do
    post = AcademicPost.create!(owner: users(:one), title: "Shared", body: "Draft")
    invitation = post.invitations.create!(inviter: users(:one), invitee: users(:two), permission: :editor)

    assert_equal 64, invitation.token.length
    assert invitation.active?
    assert invitation.acceptable_for?(users(:two))

    invitation.accept!

    membership = post.memberships.find_by!(user: users(:two))
    assert_predicate membership, :editor?
    assert_predicate membership, :active?
    assert_not invitation.reload.active?
    assert_not_nil invitation.accepted_at
  end

  test "expired, revoked, and wrong-user invitations cannot grant access" do
    post = AcademicPost.create!(owner: users(:one), title: "Shared", body: "Draft")
    invitation = post.invitations.create!(inviter: users(:one), invitee: users(:two), permission: :viewer,
                                          expires_at: 1.minute.ago)

    assert_not invitation.acceptable_for?(users(:two))
    assert_raises(ActiveRecord::RecordInvalid) { invitation.accept! }

    invitation.update!(expires_at: 1.day.from_now)
    invitation.revoke!
    assert_not invitation.acceptable_for?(users(:two))

    fresh = post.invitations.create!(inviter: users(:one), invitee: users(:two), permission: :viewer)
    assert_not fresh.acceptable_for?(users(:instructor))
  end

  test "revoking membership removes access but preserves the membership record" do
    post = AcademicPost.create!(owner: users(:one), title: "Shared", body: "Draft")
    membership = post.memberships.create!(user: users(:two), permission: :viewer)

    assert post.accessible_to?(users(:two))
    membership.revoke!

    assert_not post.reload.accessible_to?(users(:two))
    assert_not_nil membership.reload.revoked_at
  end

  test "accepting a duplicate invitation does not widen an active membership" do
    post = AcademicPost.create!(owner: users(:one), title: "Shared", body: "Draft")
    membership = post.memberships.create!(user: users(:two), permission: :viewer)
    invitation = post.invitations.create!(inviter: users(:one), invitee: users(:two), permission: :editor)

    invitation.accept!

    assert_predicate membership.reload, :viewer?
    assert_predicate membership, :active?
    assert_not invitation.reload.active?
  end
end
