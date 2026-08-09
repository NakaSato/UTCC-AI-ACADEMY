require "test_helper"

# A slug is a top-level URL: /northstar is that company's profile. The vanity
# route is declared last so every real path wins, which makes a collision a
# silently unreachable profile rather than a broken app — so the collision has
# to be impossible instead.
class OrganizationSlugTest < ActiveSupport::TestCase
  # Only the segments a valid slug could actually shadow. "robots.txt" and
  # "sitemap.xml" carry characters the slug format already refuses.
  def top_level_route_segments
    Rails.application.routes.routes.filter_map do |route|
      spec = route.path.spec.to_s
      next if spec.start_with?("/rails")

      segment = spec.split("/")[1].to_s.split("(").first.to_s
      segment if segment.match?(Organization::SLUG_FORMAT)
    end.uniq
  end

  # The list and the routes drift apart the moment someone adds a path, and the
  # drift is invisible until a company cannot open its own page.
  test "every top-level path a slug could shadow is reserved" do
    unreserved = top_level_route_segments - Organization::RESERVED_SLUGS

    assert_empty unreserved,
                 "add these to Organization::RESERVED_SLUGS: #{unreserved.join(", ")}"
  end

  test "a reserved name is refused" do
    Organization::RESERVED_SLUGS.first(5).each do |reserved|
      organization = Organization.new(name: "Taken", slug: reserved, creator: users(:admin))

      assert_not organization.valid?, "#{reserved.inspect} should be refused"
      assert_predicate organization.errors[:slug], :any?
    end
  end

  # A name that derives into a reserved slug has to be refused too, or the
  # reservation only holds for whoever types the slug by hand.
  test "a name that derives into a reserved slug is refused" do
    organization = Organization.new(name: "Admin", creator: users(:admin))

    assert_not organization.valid?
    assert_predicate organization.errors[:slug], :any?
  end

  test "an ordinary name still derives an ordinary slug" do
    organization = Organization.create!(name: "North Star Technology", creator: users(:admin))

    assert_equal "north-star-technology", organization.slug
  end
end
