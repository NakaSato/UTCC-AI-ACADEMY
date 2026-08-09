require "test_helper"

class InternshipRequestTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Request Org", creator: users(:admin),
                                        accepts_internship_requests: true)
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
    @request = @organization.internship_requests.create!(student: users(:student),
                                                        motivation: "  I follow your logistics work.  ",
                                                        learning_goals: "Route optimisation")
  end

  test "a request is position-less by construction" do
    assert_not InternshipRequest.column_names.include?("program_id"),
      "a program reference would make this a second Recruitment::InternshipApplication"
    assert_not InternshipRequest.reflect_on_all_associations.map(&:name).include?(:program)
  end

  test "a draft normalizes its text and belongs to one student and company" do
    assert_equal "I follow your logistics work.", @request.motivation
    assert_predicate @request, :draft?
    assert_equal users(:student), @request.student
    assert_equal @organization, @request.organization
  end

  test "only a student may request, and only from a company that opted in" do
    assert_not @organization.internship_requests.build(student: users(:instructor), motivation: "x",
                                                      learning_goals: "y").valid?
    assert_not @organization.internship_requests.build(student: users(:admin), motivation: "x",
                                                      learning_goals: "y").valid?

    closed = Organization.create!(name: "Closed Org", creator: users(:admin))
    assert_not closed.internship_requests.build(student: users(:student), motivation: "x",
                                               learning_goals: "y").valid?

    suspended = Organization.create!(name: "Suspended Org", creator: users(:admin), status: "suspended",
                                     accepts_internship_requests: true)
    assert_not suspended.internship_requests.build(student: users(:student), motivation: "x",
                                                  learning_goals: "y").valid?
  end

  test "a request starts as a draft and status only moves through a guarded transition" do
    assert_not @organization.internship_requests.build(student: users(:two), motivation: "x", learning_goals: "y",
                                                      status: "submitted").valid?

    @request.status = "approved"
    assert_not @request.valid?
    assert_predicate @request.errors[:status], :any?
    assert_predicate @request.reload, :draft?
  end

  test "the student submits and may withdraw while the request is open" do
    @request.submit!(actor: users(:student))

    assert_predicate @request, :submitted?
    assert_predicate @request.submitted_at, :present?
    assert_not @request.editable_by_student?

    @request.withdraw!(actor: users(:student))
    assert_predicate @request, :withdrawn?
    assert_predicate @request.withdrawn_at, :present?
  end

  test "only the student may submit or withdraw their own request" do
    [ users(:one), users(:two), users(:instructor), users(:admin) ].each do |actor|
      assert_raises(ActiveRecord::RecordInvalid, "#{actor.name} must not submit another student's request") do
        @request.submit!(actor:)
      end
    end

    assert_predicate @request.reload, :draft?
  end

  test "a company decider reviews, approves, and cannot approve twice" do
    @request.submit!(actor: users(:student))
    @request.start_review!(actor: users(:two))

    assert_predicate @request, :under_review?
    assert_predicate @request.reviewed_at, :present?

    @request.approve!(actor: users(:one))

    assert_predicate @request, :approved?
    assert_equal users(:one), @request.decided_by
    assert_predicate @request.decided_at, :present?
    assert_raises(ActiveRecord::RecordInvalid) { @request.approve!(actor: users(:one)) }
    assert_raises(ActiveRecord::RecordInvalid) { @request.reject!(actor: users(:one), reason: "Changed our mind") }
  end

  test "a rejection must state a reason" do
    @request.submit!(actor: users(:student))

    assert_raises(ActiveRecord::RecordInvalid) { @request.reject!(actor: users(:one), reason: "  ") }
    assert_predicate @request.reload, :submitted?

    @request.reject!(actor: users(:one), reason: "No capacity this term")
    assert_predicate @request, :rejected?
    assert_equal "No capacity this term", @request.decision_reason
  end

  test "mentors and outsiders cannot decide a request" do
    @request.submit!(actor: users(:student))

    [ users(:instructor), users(:student), users(:admin) ].each do |actor|
      assert_raises(ActiveRecord::RecordInvalid, "#{actor.name} must not decide the request") do
        @request.approve!(actor:)
      end
    end

    assert_predicate @request.reload, :submitted?
    assert_not @request.decidable_by?(users(:instructor))
    assert @request.decidable_by?(users(:two))
  end

  test "a decided request is immutable and the student cannot reopen it" do
    @request.submit!(actor: users(:student))
    @request.approve!(actor: users(:one))

    assert_raises(ActiveRecord::RecordInvalid) { @request.update!(motivation: "Rewritten after the decision") }
    assert_raises(ActiveRecord::RecordInvalid) { @request.withdraw!(actor: users(:student)) }
    assert_equal "I follow your logistics work.", @request.reload.motivation
  end

  test "one open request per company, and re-approach is allowed after a decision" do
    duplicate = @organization.internship_requests.build(student: users(:student), motivation: "Second try",
                                                       learning_goals: "Again")
    assert_not duplicate.valid?

    @request.submit!(actor: users(:student))
    @request.reject!(actor: users(:one), reason: "Not this term")

    reapproach = @organization.internship_requests.create!(student: users(:student), motivation: "Next term",
                                                          learning_goals: "Route optimisation")
    assert_predicate reapproach, :draft?
    assert_equal 2, @organization.internship_requests.count
  end

  test "a student may hold open requests at several companies at once" do
    other = Organization.create!(name: "Other Org", creator: users(:admin), accepts_internship_requests: true)
    second = other.internship_requests.create!(student: users(:student), motivation: "Also interested",
                                              learning_goals: "Data quality")

    assert_predicate second, :draft?
    assert_equal 2, InternshipRequest.where(student: users(:student)).count
  end

  test "a company decision survives the student's account role changing" do
    @request.submit!(actor: users(:student))
    users(:student).update!(role: "instructor")

    @request.approve!(actor: users(:one))

    assert_predicate @request.reload, :approved?
  end

  test "visibility is limited to the student and the company deciders" do
    assert @request.visible_to?(users(:student))
    assert @request.visible_to?(users(:one))
    assert @request.visible_to?(users(:two))

    [ users(:instructor), users(:admin), nil ].each do |user|
      assert_not @request.visible_to?(user), "#{user&.name || "an anonymous visitor"} must not read the request"
    end
  end

  test "request text stays inside the recorded boundary" do
    assert_not @organization.internship_requests.build(student: users(:two), motivation: " ",
                                                      learning_goals: "y").valid?
    assert_not @organization.internship_requests.build(student: users(:two), motivation: "x",
                                                      learning_goals: " ").valid?
    assert_not @organization.internship_requests.build(student: users(:two), motivation: "x" * 5_001,
                                                      learning_goals: "y").valid?
  end

  test "requests never touch the shipped internship domain or academic records" do
    assert_no_difference [ "Recruitment::InternshipApplication.count", "Recruitment::InternshipProgram.count",
                           "Enrollment.count", "Submission.count" ] do
      @request.submit!(actor: users(:student))
      @request.approve!(actor: users(:one))
    end
  end
end
