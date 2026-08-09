require "test_helper"

class BusinessCaseCommentTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Comment Case Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @business_case = @organization.business_cases.create!(owner: users(:one), title: "Service redesign")
    @business_case.transition_to!("published", actor: users(:one))
    @business_case.invitations.create!(inviter: users(:one), invitee: users(:student)).accept!
    @business_case.participants.create!(user: users(:instructor), role: "mentor", assigned_by: users(:one))
  end

  test "owners, students, and assigned mentors may comment" do
    [ users(:one), users(:student), users(:instructor) ].each do |author|
      comment = @business_case.comments.create!(author:, body: "  Feedback from #{author.name}  ")

      assert_equal "Feedback from #{author.name}", comment.body
      assert_predicate comment.posted_at, :present?
    end

    assert_equal 3, @business_case.comments.count
  end

  test "a non-participant cannot comment" do
    [ users(:two), users(:admin) ].each do |author|
      comment = @business_case.comments.build(author:, body: "Not allowed")

      assert_not comment.valid?, "#{author.name} must not comment on the case"
      assert_predicate comment.errors[:author], :any?
    end
  end

  test "comments are immutable once posted" do
    comment = @business_case.comments.create!(author: users(:one), body: "Original feedback")

    assert_not comment.update(body: "Rewritten feedback")
    assert_not comment.destroy
    assert_equal "Original feedback", comment.reload.body
  end

  test "a draft or closed case accepts no comments" do
    draft = @organization.business_cases.create!(owner: users(:one), title: "Drafting")

    assert_not draft.comments.build(author: users(:one), body: "Too early").valid?

    @business_case.transition_to!("closed", actor: users(:one))
    assert_not @business_case.comments.build(author: users(:one), body: "Too late").valid?
  end

  test "comment text stays inside the recorded boundary" do
    assert_not @business_case.comments.build(author: users(:one), body: " \n ").valid?
    assert_not @business_case.comments.build(author: users(:one), body: "x" * 4_001).valid?
  end

  test "the model records privacy-safe audit evidence for every comment" do
    assert_difference "AuditEvent.count", 1 do
      @business_case.comments.create!(author: users(:one), body: "Confidential review note")
    end

    audit = AuditEvent.order(:id).last

    assert_equal users(:one), audit.user
    assert_equal "business_case_comment_created", audit.action
    assert_equal @business_case.title, audit.params["business_case"]
    assert_not audit.params.values.any? { |value| value.to_s.include?("Confidential review note") },
      "audit evidence must not copy comment content"
    assert_predicate audit.text, :present?
  end
end
