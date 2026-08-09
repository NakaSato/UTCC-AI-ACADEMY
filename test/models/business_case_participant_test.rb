require "test_helper"

class BusinessCaseParticipantTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Participant Case Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @business_case = @organization.business_cases.create!(owner: users(:one), title: "Route optimisation")
    @business_case.transition_to!("published", actor: users(:one))
  end

  test "a mentor needs the instructor role and an owner who assigned them" do
    mentor = @business_case.participants.create!(user: users(:instructor), role: "mentor", assigned_by: users(:one))

    assert_predicate mentor, :active?
    assert_predicate mentor, :mentor?
    assert @business_case.accessible_to?(users(:instructor))

    assert_not @business_case.participants.build(user: users(:instructor), role: "mentor").valid?,
      "an unassigned instructor is not a mentor"
    assert_not @business_case.participants.build(user: users(:student), role: "mentor",
                                                assigned_by: users(:one)).valid?
    assert_not @business_case.participants.build(user: users(:instructor), role: "mentor",
                                                assigned_by: users(:two)).valid?
    assert_not @business_case.participants.build(user: users(:instructor), role: "mentor",
                                                assigned_by: users(:admin)).valid?
  end

  test "the instructor role alone never grants case access" do
    assert_not @business_case.accessible_to?(users(:instructor))
    assert_not @business_case.manageable_by?(users(:instructor))
  end

  test "a student participant must hold the student role" do
    assert @business_case.participants.build(user: users(:student), role: "student").valid?
    assert_not @business_case.participants.build(user: users(:instructor), role: "student").valid?
    assert_not @business_case.participants.build(user: users(:admin), role: "student").valid?
    assert_not @business_case.participants.build(user: users(:student), role: "reviewer").valid?
  end

  test "only one active assignment exists per case and user" do
    @business_case.participants.create!(user: users(:student), role: "student")
    duplicate = @business_case.participants.build(user: users(:student), role: "student")

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:user], :any?
  end

  test "revocation ends access without deleting the record or its evidence" do
    participant = @business_case.participants.create!(user: users(:student), role: "student")
    milestone = @business_case.milestones.create!(title: "Discovery")
    submission = @business_case.submissions.create!(milestone:, author: users(:student), body: "Findings")
    comment = @business_case.comments.create!(author: users(:student), body: "A question")

    assert_no_difference [ "BusinessCaseParticipant.count", "BusinessCaseSubmission.count",
                           "BusinessCaseComment.count" ] do
      participant.revoke!
    end

    assert_not_predicate participant, :active?
    assert_not @business_case.accessible_to?(users(:student))
    assert_equal "Findings", submission.reload.body
    assert_equal "A question", comment.reload.body
  end

  test "revocation still works after the participant's account role changes" do
    participant = @business_case.participants.create!(user: users(:student), role: "student")
    users(:student).update!(role: "instructor")

    participant.revoke!

    assert_not_predicate participant.reload, :active?
    assert_not @business_case.reload.accessible_to?(users(:student))
  end

  test "a closed case grants nobody new access" do
    @business_case.transition_to!("closed", actor: users(:one))

    mentor = @business_case.participants.build(user: users(:instructor), role: "mentor",
                                              assigned_by: users(:one))
    assert_not mentor.valid?
    assert_predicate mentor.errors[:business_case], :any?
  end

  test "a revoked participant cannot submit or comment again" do
    participant = @business_case.participants.create!(user: users(:student), role: "student")
    milestone = @business_case.milestones.create!(title: "Discovery")
    participant.revoke!

    assert_not @business_case.submissions.build(milestone:, author: users(:student), body: "After revocation").valid?
    assert_not @business_case.comments.build(author: users(:student), body: "After revocation").valid?
  end
end
