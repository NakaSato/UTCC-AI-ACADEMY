require "test_helper"

class BusinessCasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Case Controller Org", creator: users(:admin))
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @business_case = @organization.business_cases.create!(owner: users(:one), title: "Confidential margin study",
                                                         brief: "Reduce loss")
  end

  test "an owner creates, edits, publishes, and closes a case with audit evidence" do
    sign_in_as users(:one)

    assert_difference [ "BusinessCase.count", "AuditEvent.count" ], 1 do
      post business_cases_path, params: {
        business_case: { organization_id: @organization.id, title: "New challenge", brief: "Try this" }
      }
    end

    created = BusinessCase.order(:id).last
    assert_redirected_to business_case_path(created)
    assert_predicate created, :draft?
    assert_equal users(:one), created.owner

    patch business_case_path(created), params: { business_case: { title: "Refined challenge" } }
    assert_redirected_to business_case_path(created)
    assert_equal "Refined challenge", created.reload.title

    assert_difference "AuditEvent.count", 1 do
      post publish_business_case_path(created), params: { lock_version: created.lock_version }
    end
    assert_predicate created.reload, :published?

    assert_difference "AuditEvent.count", 1 do
      post close_business_case_path(created), params: { lock_version: created.lock_version }
    end
    assert_predicate created.reload, :closed?

    audit = AuditEvent.where(action: "business_case_closed").order(:id).last
    assert_equal @organization.name, audit.params["organization"]
    assert_predicate audit.text, :present?
    assert_equal :warn, audit.level
  end

  test "the invite panel tells a draft case apart from a closed one" do
    sign_in_as users(:one)

    get business_case_path(@business_case)
    assert_response :success
    assert_includes response.body, I18n.t("business_cases.show.invitations_draft")
    assert_not_includes response.body, I18n.t("business_cases.show.invitations_closed")

    @business_case.transition_to!("published", actor: users(:one))
    @business_case.transition_to!("closed", actor: users(:one))

    get business_case_path(@business_case)
    assert_response :success
    assert_includes response.body, I18n.t("business_cases.show.invitations_closed")
    assert_not_includes response.body, I18n.t("business_cases.show.invitations_draft")
  end

  test "consecutive milestone and invitation forms use complete navigations" do
    sign_in_as users(:one)
    @business_case.transition_to!("published", actor: users(:one))

    get business_case_path(@business_case)

    assert_response :success
    assert_select "form[action=?][data-turbo=false]", milestones_business_case_path(@business_case), count: 1
    assert_select "form[action=?][data-turbo=false]", invitations_business_case_path(@business_case), count: 1
  end

  test "a closed case cannot be edited through the request path" do
    sign_in_as users(:one)
    @business_case.transition_to!("published", actor: users(:one))
    @business_case.transition_to!("closed", actor: users(:one))

    get edit_business_case_path(@business_case)
    assert_redirected_to business_case_path(@business_case)

    patch business_case_path(@business_case), params: { business_case: { title: "Reopened by edit" } }
    assert_redirected_to business_case_path(@business_case)
    assert_equal "Confidential margin study", @business_case.reload.title
  end

  test "a stale lock version reports a conflict instead of transitioning" do
    sign_in_as users(:one)

    post publish_business_case_path(@business_case), params: { lock_version: @business_case.lock_version + 3 }

    assert_redirected_to business_case_path(@business_case)
    assert_predicate @business_case.reload, :draft?
  end

  test "no non-participant can read a case or learn that it exists" do
    other_organization = Organization.create!(name: "Unrelated Org", creator: users(:admin))
    other_organization.memberships.create!(user: users(:student), role: "owner")
    # The 404 itself is the non-disclosure guarantee: the loader raises before any
    # view runs, so nothing renders the case. Asserting against the body would
    # only inspect the test environment's debug page, which echoes this file.
    [ users(:two), users(:student), users(:instructor), users(:admin) ].each do |user|
      sign_in_as user

      get business_case_path(@business_case)
      assert_response :not_found, "#{user.name} must not read the case"

      get edit_business_case_path(@business_case)
      assert_response :not_found

      post publish_business_case_path(@business_case)
      assert_response :not_found
      assert_predicate @business_case.reload, :draft?

      sign_out
    end

    # The owner does see it, so the four 404s above are not false passes.
    sign_in_as users(:one)
    get business_case_path(@business_case)
    assert_response :success
    assert_includes response.body, @business_case.title
  end

  test "a revoked participant loses read access" do
    @business_case.transition_to!("published", actor: users(:one))
    @business_case.invitations.create!(inviter: users(:one), invitee: users(:student)).accept!

    sign_in_as users(:student)
    get business_case_path(@business_case)
    assert_response :success

    @business_case.participants.find_by(user: users(:student)).revoke!

    get business_case_path(@business_case)
    assert_response :not_found
  end

  test "a student sees only their own submissions while an owner reviews every one" do
    @business_case.transition_to!("published", actor: users(:one))
    milestone = @business_case.milestones.create!(title: "Discovery")
    @business_case.invitations.create!(inviter: users(:one), invitee: users(:student)).accept!
    @business_case.invitations.create!(inviter: users(:one), invitee: users(:two)).accept!
    @business_case.submissions.create!(milestone:, author: users(:student), body: "Student three findings")
    @business_case.submissions.create!(milestone:, author: users(:two), body: "Student two findings")

    sign_in_as users(:student)
    get business_case_path(@business_case)
    assert_response :success
    assert_includes response.body, "Student three findings"
    assert_not_includes response.body, "Student two findings"

    sign_out
    sign_in_as users(:one)
    get business_case_path(@business_case)
    assert_response :success
    assert_includes response.body, "Student three findings"
    assert_includes response.body, "Student two findings"
  end

  test "an assigned mentor reads the case but cannot change its lifecycle" do
    @business_case.transition_to!("published", actor: users(:one))
    @business_case.participants.create!(user: users(:instructor), role: "mentor", assigned_by: users(:one))

    sign_in_as users(:instructor)
    get business_case_path(@business_case)
    assert_response :success

    get edit_business_case_path(@business_case)
    assert_response :not_found

    post close_business_case_path(@business_case)
    assert_response :not_found
    assert_predicate @business_case.reload, :published?
  end

  test "the index lists managed and participating cases only" do
    @business_case.transition_to!("published", actor: users(:one))
    @business_case.invitations.create!(inviter: users(:one), invitee: users(:student)).accept!
    hidden_organization = Organization.create!(name: "Hidden Org", creator: users(:admin))
    hidden_organization.memberships.create!(user: users(:two), role: "owner")
    hidden_organization.business_cases.create!(owner: users(:two), title: "Hidden challenge")

    sign_in_as users(:one)
    get business_cases_path
    assert_response :success
    assert_includes response.body, "Confidential margin study"
    assert_not_includes response.body, "Hidden challenge"

    sign_out
    sign_in_as users(:student)
    get business_cases_path
    assert_response :success
    assert_includes response.body, "Confidential margin study"
    assert_not_includes response.body, "Hidden challenge"

    sign_out
    sign_in_as users(:instructor)
    get business_cases_path
    assert_response :success
    assert_not_includes response.body, "Confidential margin study"
  end

  test "only an organization owner reaches the new-case form" do
    sign_in_as users(:one)
    get new_business_case_path
    assert_response :success

    sign_out
    sign_in_as users(:two)
    get new_business_case_path
    assert_response :not_found

    sign_out
    sign_in_as users(:admin)
    get new_business_case_path
    assert_response :not_found
  end

  test "a company reviewer runs the case surfaces the owner can" do
    @organization.memberships.create!(user: users(:student), role: "company_reviewer")
    sign_in_as users(:student)

    get new_business_case_path
    assert_response :success

    assert_difference "BusinessCase.count", 1 do
      post business_cases_path, params: {
        business_case: { organization_id: @organization.id, title: "Reviewer challenge" }
      }
    end
    created = BusinessCase.order(:id).last

    post publish_business_case_path(created), params: { lock_version: created.lock_version }
    assert_predicate created.reload, :published?

    assert_difference "BusinessCaseInvitation.count", 1 do
      post invitations_business_case_path(created), params: { invitation: { user_id: users(:two).id } }
    end

    # The owner's existing case is in the same organization, so it is theirs to run too.
    get business_case_path(@business_case)
    assert_response :success

    get business_cases_path
    assert_response :success
    assert_includes response.body, "Reviewer challenge"
    assert_includes response.body, "Confidential margin study"
  end

  test "case work never mutates recruitment applications or academic progress" do
    job = @organization.job_posts.create!(creator: users(:one), title: "Analyst", summary: "Evidence first.",
                                          description: "Work with the team.", category: "Product",
                                          department: "Academy", team: "Platform", seniority: "Junior",
                                          location: "Bangkok")
    job.transition_to!("review")
    job.transition_to!("published")
    CandidateProfile.create!(user: users(:student), application_data_reuse_consent: true)
    application = Recruitment::JobApplication.submit!(job_post: job, candidate: users(:student), statement: "Ready")

    @business_case.transition_to!("published", actor: users(:one))
    milestone = @business_case.milestones.create!(title: "Discovery")
    @business_case.invitations.create!(inviter: users(:one), invitee: users(:student)).accept!

    sign_in_as users(:student)

    assert_no_changes -> { application.reload.status } do
      assert_no_difference [ "Recruitment::JobApplication.count", "Enrollment.count", "Submission.count",
                             "TopicCompletion.count" ] do
        post milestone_submissions_business_case_path(@business_case, milestone_id: milestone.id),
             params: { submission: { body: "Case findings only" } }
        post comments_business_case_path(@business_case), params: { comment: { body: "A question" } }
      end
    end

    assert_equal 1, @business_case.submissions.count
  end
end
