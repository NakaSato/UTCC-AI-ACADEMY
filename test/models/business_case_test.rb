require "test_helper"

class BusinessCaseTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Case Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @business_case = @organization.business_cases.create!(owner: users(:one), title: "  Reduce delivery waste  ",
                                                          brief: "Cut packaging cost", requirements: "Bangkok data only")
  end

  test "a case belongs to one active organization and one owning member" do
    assert_equal "Reduce delivery waste", @business_case.title
    assert_equal @organization, @business_case.organization
    assert_predicate @business_case, :draft?

    assert_not @organization.business_cases.build(owner: users(:two), title: "Recruiter owned").valid?,
      "an organization role other than owner cannot own a case"
    assert_not @organization.business_cases.build(owner: users(:student), title: "Outsider owned").valid?

    suspended = Organization.create!(name: "Suspended Org", creator: users(:admin), status: "suspended")
    suspended.memberships.create!(user: users(:one), role: "owner")
    assert_not suspended.business_cases.build(owner: users(:one), title: "Suspended case").valid?
  end

  test "a case cannot be moved to another organization" do
    other = Organization.create!(name: "Other Org", creator: users(:admin))
    other.memberships.create!(user: users(:one), role: "owner")

    assert_raises(ActiveRecord::RecordNotSaved) { @business_case.update!(organization: other) }
    assert_equal @organization.id, @business_case.reload.organization_id
  end

  test "status only changes through a guarded transition" do
    @business_case.status = "published"

    assert_not @business_case.valid?
    assert_predicate @business_case.errors[:status], :any?
    assert_equal "draft", @business_case.reload.status
  end

  test "the transition table is the only lifecycle path" do
    @business_case.transition_to!("published", actor: users(:one))

    assert_predicate @business_case, :published?
    assert_predicate @business_case.published_at, :present?
    assert_predicate @business_case, :open_for_invitations?

    @business_case.transition_to!("closed", actor: users(:one))

    assert_predicate @business_case, :closed?
    assert_predicate @business_case.closed_at, :present?
    assert_not @business_case.open_for_submissions?
    assert_raises(ActiveRecord::RecordInvalid) { @business_case.transition_to!("published", actor: users(:one)) }
  end

  test "only an active owner can transition a case" do
    [ users(:two), users(:student), users(:instructor), users(:admin) ].each do |actor|
      assert_raises(ActiveRecord::RecordInvalid, "#{actor.name} must not transition the case") do
        @business_case.transition_to!("published", actor:)
      end
    end

    assert_equal "draft", @business_case.reload.status
  end

  test "a stale lock version cannot transition the case" do
    assert_raises(ActiveRecord::StaleObjectError) do
      @business_case.transition_to!("published", actor: users(:one), lock_version: @business_case.lock_version + 5)
    end

    assert_equal "draft", @business_case.reload.status
  end

  test "a closed case rejects ordinary edits, milestones, invitations, submissions, and comments" do
    @business_case.transition_to!("published", actor: users(:one))
    invitation = @business_case.invitations.create!(inviter: users(:one), invitee: users(:student))
    invitation.accept!
    milestone = @business_case.milestones.create!(title: "Discovery")
    @business_case.transition_to!("closed", actor: users(:one))

    assert_raises(ActiveRecord::RecordInvalid) { @business_case.update!(title: "Renamed after closure") }
    assert_not @business_case.milestones.build(title: "Late milestone").valid?
    assert_not @business_case.invitations.build(inviter: users(:one), invitee: users(:two)).valid?
    assert_not @business_case.submissions.build(milestone:, author: users(:student), body: "Late work").valid?
    assert_not @business_case.comments.build(author: users(:one), body: "Late comment").valid?
    assert_equal "Reduce delivery waste", @business_case.reload.title
  end

  test "case access comes from ownership or an active participant assignment only" do
    @business_case.transition_to!("published", actor: users(:one))

    assert @business_case.manageable_by?(users(:one))
    assert @business_case.accessible_to?(users(:one))

    [ users(:two), users(:student), users(:instructor), users(:admin), nil ].each do |user|
      assert_not @business_case.manageable_by?(user), "#{user&.name || "an anonymous visitor"} must not manage the case"
      assert_not @business_case.accessible_to?(user), "#{user&.name || "an anonymous visitor"} must not read the case"
    end

    participant = @business_case.participants.create!(user: users(:instructor), role: "mentor",
                                                     assigned_by: users(:one))
    assert @business_case.accessible_to?(users(:instructor))

    participant.revoke!
    assert_not @business_case.accessible_to?(users(:instructor))
  end

  test "a suspended organization closes management and collaboration" do
    @business_case.transition_to!("published", actor: users(:one))
    @organization.update!(status: "suspended")

    assert_not @business_case.reload.manageable_by?(users(:one))
    assert_not @business_case.open_for_invitations?
    assert_not @business_case.open_for_submissions?
  end
end
