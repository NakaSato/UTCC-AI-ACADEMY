require "test_helper"

class BusinessCaseWorkspaceTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Workspace Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @business_case = @organization.business_cases.create!(owner: users(:one), title: "Checkout abandonment")
    @business_case.transition_to!("published", actor: users(:one))
    @business_case.invitations.create!(inviter: users(:one), invitee: users(:student)).accept!
  end

  test "an owner adds and completes milestones with audit evidence" do
    sign_in_as users(:one)

    assert_difference [ "BusinessCaseMilestone.count", "AuditEvent.count" ], 1 do
      post milestones_business_case_path(@business_case), params: {
        milestone: { title: "Discovery", description: "Interview five customers" }
      }
    end

    milestone = @business_case.milestones.order(:id).last
    assert_redirected_to business_case_path(@business_case)
    assert_equal 1, milestone.position

    assert_difference "AuditEvent.count", 1 do
      post complete_milestone_business_case_path(@business_case, milestone_id: milestone.id)
    end

    assert_predicate milestone.reload, :completed?
  end

  test "a student submits work that the owner and mentor can read and nobody can rewrite" do
    milestone = @business_case.milestones.create!(title: "Discovery")
    @business_case.participants.create!(user: users(:instructor), role: "mentor", assigned_by: users(:one))

    sign_in_as users(:student)

    assert_difference [ "BusinessCaseSubmission.count", "AuditEvent.count" ], 1 do
      post milestone_submissions_business_case_path(@business_case, milestone_id: milestone.id),
           params: { submission: { body: "We found three drop-off points." } }
    end

    submission = @business_case.submissions.order(:id).last
    assert_redirected_to business_case_path(@business_case)
    assert_equal 1, submission.version
    assert_equal users(:student), submission.author

    post milestone_submissions_business_case_path(@business_case, milestone_id: milestone.id),
         params: { submission: { body: "Revised with a fourth point." } }

    assert_equal [ 1, 2 ], @business_case.submissions.order(:version).map(&:version)
    assert_equal "We found three drop-off points.", submission.reload.body

    sign_out
    sign_in_as users(:instructor)
    get business_case_path(@business_case)
    assert_response :success
    assert_includes response.body, "We found three drop-off points."
  end

  test "only an active student participant can submit" do
    milestone = @business_case.milestones.create!(title: "Discovery")

    [ users(:one), users(:two), users(:instructor), users(:admin) ].each do |user|
      sign_in_as user

      assert_no_difference "BusinessCaseSubmission.count" do
        post milestone_submissions_business_case_path(@business_case, milestone_id: milestone.id),
             params: { submission: { body: "Not my work" } }
      end
      assert_response :not_found, "#{user.name} must not submit case work"

      sign_out
    end
  end

  test "a mentor may comment but may not manage milestones or participants" do
    @business_case.participants.create!(user: users(:instructor), role: "mentor", assigned_by: users(:one))
    milestone = @business_case.milestones.create!(title: "Discovery")

    sign_in_as users(:instructor)

    assert_difference [ "BusinessCaseComment.count", "AuditEvent.count" ], 1 do
      post comments_business_case_path(@business_case), params: { comment: { body: "Consider a control group." } }
    end
    assert_redirected_to business_case_path(@business_case)

    assert_no_difference "BusinessCaseMilestone.count" do
      post milestones_business_case_path(@business_case), params: { milestone: { title: "Mentor milestone" } }
    end
    assert_response :not_found

    post complete_milestone_business_case_path(@business_case, milestone_id: milestone.id)
    assert_response :not_found
    assert_predicate milestone.reload, :open?

    assert_no_difference "BusinessCaseInvitation.count" do
      post invitations_business_case_path(@business_case), params: { invitation: { user_id: users(:two).id } }
    end
    assert_response :not_found
  end

  test "an owner assigns and revokes a mentor without deleting their feedback" do
    sign_in_as users(:one)

    assert_difference [ "BusinessCaseParticipant.count", "AuditEvent.count" ], 1 do
      post participants_business_case_path(@business_case), params: { participant: { user_id: users(:instructor).id } }
    end
    assert_redirected_to business_case_path(@business_case)

    mentor_comment = @business_case.comments.create!(author: users(:instructor), body: "Mentor feedback")

    assert_no_difference [ "BusinessCaseParticipant.count", "BusinessCaseComment.count" ] do
      assert_difference "AuditEvent.count", 1 do
        delete participant_business_case_path(@business_case, user_id: users(:instructor).id)
      end
    end

    assert_redirected_to business_case_path(@business_case)
    assert_not @business_case.reload.accessible_to?(users(:instructor))
    assert_equal "Mentor feedback", mentor_comment.reload.body

    audit = AuditEvent.where(action: "business_case_participant_revoked").order(:id).last
    assert_equal :warn, audit.level
  end

  test "a revoked student loses the workspace entirely" do
    milestone = @business_case.milestones.create!(title: "Discovery")
    @business_case.participants.find_by(user: users(:student)).revoke!

    sign_in_as users(:student)

    get business_case_path(@business_case)
    assert_response :not_found

    assert_no_difference "BusinessCaseSubmission.count" do
      post milestone_submissions_business_case_path(@business_case, milestone_id: milestone.id),
           params: { submission: { body: "After revocation" } }
    end
    assert_response :not_found

    assert_no_difference "BusinessCaseComment.count" do
      post comments_business_case_path(@business_case), params: { comment: { body: "After revocation" } }
    end
    assert_response :not_found
  end

  test "a closed case rejects every workspace write" do
    milestone = @business_case.milestones.create!(title: "Discovery")
    @business_case.transition_to!("closed", actor: users(:one))

    sign_in_as users(:student)

    assert_no_difference "BusinessCaseSubmission.count" do
      post milestone_submissions_business_case_path(@business_case, milestone_id: milestone.id),
           params: { submission: { body: "Late work" } }
    end
    assert_redirected_to business_case_path(@business_case)

    assert_no_difference "BusinessCaseComment.count" do
      post comments_business_case_path(@business_case), params: { comment: { body: "Late comment" } }
    end
    assert_redirected_to business_case_path(@business_case)

    sign_out
    sign_in_as users(:one)

    assert_no_difference "BusinessCaseMilestone.count" do
      post milestones_business_case_path(@business_case), params: { milestone: { title: "Late milestone" } }
    end
    assert_redirected_to business_case_path(@business_case)

    assert_no_difference "BusinessCaseInvitation.count" do
      post invitations_business_case_path(@business_case), params: { invitation: { user_id: users(:two).id } }
    end
    assert_redirected_to business_case_path(@business_case)

    # A closed case still reads for its participants; only writing is gone.
    get business_case_path(@business_case)
    assert_response :success
  end

  test "a submission notifies the organization owners without copying the work" do
    milestone = @business_case.milestones.create!(title: "Discovery")

    sign_in_as users(:student)

    assert_difference "Notification.count", 1 do
      post milestone_submissions_business_case_path(@business_case, milestone_id: milestone.id),
           params: { submission: { body: "Sensitive working notes" } }
    end

    notification = users(:one).notifications.order(:id).last

    assert_equal "business_case_submission_received", notification.kind
    assert_equal business_case_path(@business_case), notification.action_path
    assert_not notification.params.value?("Sensitive working notes")
    assert_predicate notification.text, :present?
  end
end
