require "test_helper"

class BusinessCaseMilestoneTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Milestone Case Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @business_case = @organization.business_cases.create!(owner: users(:one), title: "Warehouse layout")
    @business_case.transition_to!("published", actor: users(:one))
  end

  test "milestones take sequential positions inside one case" do
    first = @business_case.milestones.create!(title: "  Discovery  ")
    second = @business_case.milestones.create!(title: "Prototype")

    assert_equal "Discovery", first.title
    assert_equal [ 1, 2 ], [ first.position, second.position ]
    assert_predicate first, :open?
    assert_equal [ first, second ], @business_case.milestones.ordered.to_a
  end

  test "a position is unique within a case but independent across cases" do
    @business_case.milestones.create!(title: "Discovery")
    duplicate = @business_case.milestones.build(title: "Duplicate", position: 1)

    assert_not duplicate.valid?

    other_case = @organization.business_cases.create!(owner: users(:one), title: "Second case")
    assert other_case.milestones.build(title: "Discovery", position: 1).valid?
  end

  test "completion is a one-way guarded transition" do
    milestone = @business_case.milestones.create!(title: "Discovery")
    milestone.complete!

    assert_predicate milestone, :completed?
    assert_predicate milestone.completed_at, :present?
    assert_raises(ActiveRecord::RecordInvalid) { milestone.complete! }
  end

  test "a closed case accepts no new or completing milestones" do
    milestone = @business_case.milestones.create!(title: "Discovery")
    @business_case.transition_to!("closed", actor: users(:one))

    assert_not @business_case.milestones.build(title: "Late").valid?
    assert_raises(ActiveRecord::RecordInvalid) { milestone.reload.complete! }
    assert_predicate milestone.reload, :open?
  end

  test "milestone text stays inside the recorded boundary" do
    assert_not @business_case.milestones.build(title: " ").valid?
    assert_not @business_case.milestones.build(title: "x" * 161).valid?
    assert_not @business_case.milestones.build(title: "Valid", description: "x" * 10_001).valid?
  end
end
