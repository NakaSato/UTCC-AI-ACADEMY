require "test_helper"

class InternshipRequestDecisionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Decision Org", creator: users(:admin),
                                        accepts_internship_requests: true)
    @organization.memberships.create!(user: users(:one), role: "owner")
    @organization.memberships.create!(user: users(:two), role: "recruiter")
    @organization.memberships.create!(user: users(:instructor), role: "mentor")
    @internship_request = @organization.internship_requests.create!(student: users(:student),
                                                       motivation: "Your routing work",
                                                       learning_goals: "Optimisation")
    @internship_request.submit!(actor: users(:student))
  end

  test "a decider reviews then approves, notifying the student with an audited decision" do
    sign_in_as users(:two)

    get organization_internship_requests_path(@organization)
    assert_response :success
    assert_includes response.body, users(:student).name
    assert_includes response.body, "Your routing work"

    assert_difference "AuditEvent.count", 1 do
      post review_internship_request_path(@internship_request)
    end
    assert_predicate @internship_request.reload, :under_review?

    assert_difference [ "AuditEvent.count", "Notification.count" ], 1 do
      post approve_internship_request_path(@internship_request)
    end

    assert_redirected_to organization_internship_requests_path(@organization)
    assert_predicate @internship_request.reload, :approved?
    assert_equal users(:two), @internship_request.decided_by

    notification = users(:student).notifications.order(:id).last
    assert_equal "internship_request_decided", notification.kind
    assert_equal internship_request_path(@internship_request), notification.action_path

    audit = AuditEvent.where(action: "internship_request_approved").order(:id).last
    assert_equal users(:student).name, audit.params["student"]
    assert_not audit.params.value?("Your routing work"), "an audit row must not copy the request text"
    assert_predicate audit.text, :present?
  end

  test "a rejection requires a reason and is recorded once" do
    sign_in_as users(:one)

    post reject_internship_request_path(@internship_request), params: { decision_reason: "" }
    assert_redirected_to organization_internship_requests_path(@organization)
    assert_predicate @internship_request.reload, :submitted?

    post reject_internship_request_path(@internship_request), params: { decision_reason: "No capacity this term" }
    assert_predicate @internship_request.reload, :rejected?
    assert_equal "No capacity this term", @internship_request.decision_reason

    post approve_internship_request_path(@internship_request)
    assert_redirected_to organization_internship_requests_path(@organization)
    assert_predicate @internship_request.reload, :rejected?
  end

  test "a mentor, another company, a student, and an admin cannot decide" do
    other = Organization.create!(name: "Other Decision Org", creator: users(:admin))
    other.memberships.create!(user: users(:one), role: "owner")

    [ users(:instructor), users(:student), users(:admin) ].each do |user|
      sign_in_as user

      get organization_internship_requests_path(@organization)
      assert_response :not_found, "#{user.name} must not read the request queue"

      post approve_internship_request_path(@internship_request)
      assert_response :not_found
      assert_predicate @internship_request.reload, :submitted?

      sign_out
    end
  end

  test "a draft request is not exposed to the company" do
    draft = @organization.internship_requests.create!(student: users(:two), motivation: "Still private",
                                                     learning_goals: "Still private")

    sign_in_as users(:one)
    get organization_internship_requests_path(@organization)

    assert_response :success
    assert_not_includes response.body, "Still private"
    assert_includes response.body, I18n.t("internship_requests.draft_hidden")
    assert_predicate draft.reload, :draft?
  end

  test "only the accountable roles may open or close the request channel" do
    sign_in_as users(:two)
    patch organization_internship_request_settings_path(@organization),
          params: { accepts_internship_requests: false }
    assert_response :not_found
    assert_predicate @organization.reload, :accepts_internship_requests?

    sign_out
    sign_in_as users(:one)

    assert_difference "AuditEvent.count", 1 do
      patch organization_internship_request_settings_path(@organization),
            params: { accepts_internship_requests: false }
    end
    assert_redirected_to organization_internship_requests_path(@organization)
    assert_not @organization.reload.accepts_internship_requests?

    audit = AuditEvent.order(:id).last
    assert_equal "internship_requests_closed", audit.action
  end

  test "a decision never mutates the shipped internship domain or academic records" do
    sign_in_as users(:one)

    assert_no_difference [ "Recruitment::InternshipApplication.count", "Recruitment::InternshipProgram.count",
                           "Recruitment::InternshipEvaluation.count", "Enrollment.count", "Submission.count",
                           "TopicCompletion.count" ] do
      post approve_internship_request_path(@internship_request)
    end

    assert_predicate @internship_request.reload, :approved?
  end
end
