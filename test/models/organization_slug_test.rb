require "test_helper"

# The slug is the organization's name in every URL it appears in — the profile
# at /company/north-star and the workspace routes behind it.
class OrganizationSlugTest < ActiveSupport::TestCase
  test "an ordinary name derives an ordinary slug" do
    organization = Organization.create!(name: "North Star Technology", creator: users(:admin))

    assert_equal "north-star-technology", organization.slug
  end

  test "the slug is what a path helper writes, not the row id" do
    organization = Organization.create!(name: "Path Co", creator: users(:admin))

    assert_equal "path-co", organization.to_param
    assert_equal organization, Organization.from_param!("path-co")
  end

  # The /company prefix is what makes this safe. A name that would have shadowed
  # a real path at the root is just a company under it.
  test "a name that matches a route is allowed under the prefix" do
    %w[admin login map].each do |name|
      organization = Organization.create!(name: name.capitalize, creator: users(:admin))

      assert_equal name, organization.slug
      assert_equal "/company/#{name}",
                   Rails.application.routes.url_helpers.company_path(organization)
    end
  end

  # A blank one is absent from the list on purpose: `derive_slug` fills it in
  # from the name before validation, so blank is corrected rather than refused.
  test "a slug still has to look like a slug" do
    [ "Not A Slug", "trailing-", "under_score" ].each do |bad|
      organization = Organization.new(name: "X", slug: bad, creator: users(:admin))

      assert_not organization.valid?, "#{bad.inspect} should be rejected"
      assert_predicate organization.errors[:slug], :any?
    end
  end
end
