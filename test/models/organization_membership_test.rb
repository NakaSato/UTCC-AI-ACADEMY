require "test_helper"

class OrganizationMembershipTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Recruitment Org", creator: users(:admin))
  end

  test "accepts recruitment roles and blocks admin members" do
    membership = @organization.memberships.new(user: users(:one), role: "recruiter")
    assert_predicate membership, :valid?

    admin_membership = @organization.memberships.new(user: users(:admin), role: "recruiter")
    assert_not admin_membership.valid?
    assert_predicate admin_membership.errors[:user], :any?
  end

  test "a company reviewer is a grantable, revocable, invitable role" do
    membership = @organization.memberships.create!(user: users(:one), role: "company_reviewer")

    assert_predicate membership, :company_reviewer?
    assert_predicate membership, :active?
    assert_includes OrganizationInvitation::ROLES, "company_reviewer",
      "a company reviewer must be invitable; only ownership is withheld"

    membership.revoke!
    assert_not_predicate membership.reload, :active?
  end

  test "a user can have only one membership in an organization" do
    @organization.memberships.create!(user: users(:one), role: "recruiter")
    duplicate = @organization.memberships.new(user: users(:one), role: "mentor")

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:user_id], :any?
  end

  test "only one active owner is allowed and owners cannot be revoked" do
    owner = @organization.memberships.create!(user: users(:one), role: "owner")
    second_owner = @organization.memberships.new(user: users(:two), role: "owner")

    assert_raises(ActiveRecord::RecordNotUnique) { second_owner.save!(validate: false) }
    assert_raises(ActiveRecord::RecordInvalid) { owner.revoke! }
    assert_predicate owner.reload, :active?
  end

  test "revoking a non-owner keeps the membership record for auditability" do
    membership = @organization.memberships.create!(user: users(:one), role: "recruiter")

    membership.revoke!

    assert_not_predicate membership.reload, :active?
    assert_equal "revoked", membership.status
  end
end
