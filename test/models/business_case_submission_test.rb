require "test_helper"

class BusinessCaseSubmissionTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Submission Case Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @business_case = @organization.business_cases.create!(owner: users(:one), title: "Demand forecasting")
    @business_case.transition_to!("published", actor: users(:one))
    @milestone = @business_case.milestones.create!(title: "Discovery")
    @business_case.invitations.create!(inviter: users(:one), invitee: users(:student)).accept!
  end

  test "an active student participant submits normalized text evidence" do
    submission = @business_case.submissions.create!(milestone: @milestone, author: users(:student),
                                                    body: "  Our findings.  ")

    assert_equal "Our findings.", submission.body
    assert_equal 1, submission.version
    assert_predicate submission.submitted_at, :present?
  end

  test "only the author's own active student participation authorizes a submission" do
    [ users(:one), users(:two), users(:instructor), users(:admin) ].each do |author|
      submission = @business_case.submissions.build(milestone: @milestone, author:, body: "Not mine")

      assert_not submission.valid?, "#{author.name} must not submit case work"
      assert_predicate submission.errors[:author], :any?
    end
  end

  test "authorization is re-derived at write time, not from a loaded object" do
    stale_case = BusinessCase.find(@business_case.id)
    @business_case.participants.find_by(user: users(:student)).revoke!

    unauthorized = stale_case.submissions.build(milestone: @milestone, author: users(:student), body: "Revoked")

    assert_not unauthorized.valid?
    assert_predicate unauthorized.errors[:author], :any?
  end

  test "revisions append a new version and never rewrite the original" do
    first = @business_case.submissions.create!(milestone: @milestone, author: users(:student), body: "First pass")
    second = @business_case.submissions.create!(milestone: @milestone, author: users(:student), body: "Second pass")

    assert_equal [ 1, 2 ], [ first.version, second.version ]
    assert_not first.update(body: "Rewritten history")
    assert_not first.destroy
    assert_equal "First pass", first.reload.body
    assert_equal [ second, first ], @business_case.submissions.newest_first.to_a
  end

  test "the feed reads chronologically, not by per-author version number" do
    other_milestone = @business_case.milestones.create!(title: "Prototype")
    @business_case.invitations.create!(inviter: users(:one), invitee: users(:two)).accept!

    older = @business_case.submissions.create!(milestone: @milestone, author: users(:student),
                                              body: "First pass")
    older.update_columns(submitted_at: 2.weeks.ago)
    revision = @business_case.submissions.create!(milestone: @milestone, author: users(:student),
                                                 body: "Second pass")
    revision.update_columns(submitted_at: 10.days.ago)
    newest = @business_case.submissions.create!(milestone: other_milestone, author: users(:two),
                                                body: "Brand new work")

    assert_equal [ newest, revision, older ], @business_case.submissions.newest_first.to_a
    assert_equal 1, newest.version, "a first submission is version 1 yet must still sort first"
  end

  test "a duplicate version conflicts in the database and preserves the original" do
    first = @business_case.submissions.create!(milestone: @milestone, author: users(:student), body: "First pass")
    conflicting = @business_case.submissions.build(milestone: @milestone, author: users(:student), body: "Racing pass",
                                                   submitted_at: Time.current)
    conflicting.version = first.version

    assert_raises(ActiveRecord::RecordNotUnique) { conflicting.save!(validate: false) }
    assert_equal "First pass", first.reload.body
    assert_equal 1, @business_case.submissions.count
  end

  test "a submission belongs to one case and cannot borrow another case's milestone" do
    other_case = @organization.business_cases.create!(owner: users(:one), title: "Other case")
    other_case.transition_to!("published", actor: users(:one))
    other_milestone = other_case.milestones.create!(title: "Elsewhere")

    submission = @business_case.submissions.build(milestone: other_milestone, author: users(:student),
                                                  body: "Wrong case")

    assert_not submission.valid?
    assert_predicate submission.errors[:milestone], :any?
  end

  test "a draft or closed case accepts no submissions" do
    draft = @organization.business_cases.create!(owner: users(:one), title: "Drafting")
    draft_milestone = draft.milestones.create!(title: "Discovery")

    assert_not draft.submissions.build(milestone: draft_milestone, author: users(:student), body: "Too early").valid?

    @business_case.transition_to!("closed", actor: users(:one))
    assert_not @business_case.submissions.build(milestone: @milestone, author: users(:student),
                                                body: "Too late").valid?
  end

  test "submission text stays inside the recorded boundary" do
    assert_not @business_case.submissions.build(milestone: @milestone, author: users(:student), body: " \n ").valid?
    assert_not @business_case.submissions.build(milestone: @milestone, author: users(:student),
                                                body: "x" * 10_001).valid?
  end

  test "the model records privacy-safe audit evidence for every submission" do
    assert_difference "AuditEvent.count", 1 do
      @business_case.submissions.create!(milestone: @milestone, author: users(:student), body: "Confidential findings")
    end

    audit = AuditEvent.order(:id).last

    assert_equal users(:student), audit.user
    assert_equal "business_case_submission_created", audit.action
    assert_equal @business_case.title, audit.params["business_case"]
    assert_equal @milestone.title, audit.params["milestone"]
    assert_not audit.params.values.any? { |value| value.to_s.include?("Confidential findings") },
      "audit evidence must not copy submission content"
    assert_predicate audit.text, :present?
  end

  test "case submissions never touch recruitment or academic records" do
    assert_no_difference [ "Recruitment::JobApplication.count", "Enrollment.count", "Submission.count" ] do
      @business_case.submissions.create!(milestone: @milestone, author: users(:student), body: "Case work only")
    end
  end
end
