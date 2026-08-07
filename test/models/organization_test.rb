require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "derives a unique slug from the name" do
    organization = Organization.new(name: "Acme & Sons", creator: users(:admin))

    assert_predicate organization, :valid?
    assert_equal "acme-sons", organization.slug
  end

  test "rejects a duplicate slug" do
    Organization.create!(name: "Acme", slug: "acme", creator: users(:admin))
    duplicate = Organization.new(name: "Another Acme", slug: "ACME", creator: users(:admin))

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:slug], :any?
  end

  test "a member is visible and a non-member is not" do
    organization = Organization.create!(name: "Visible", creator: users(:admin))
    organization.memberships.create!(user: users(:one), role: "owner")

    assert organization.visible_to?(users(:one))
    assert organization.visible_to?(users(:admin))
    assert_not organization.visible_to?(users(:two))
  end
end
