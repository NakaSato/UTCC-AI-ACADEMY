require "test_helper"

class InternshipRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Student Request Org", creator: users(:admin),
                                        accepts_internship_requests: true)
    @organization.memberships.create!(user: users(:one), role: "owner")
    @closed = Organization.create!(name: "Not Accepting Org", creator: users(:admin))
    @closed.memberships.create!(user: users(:two), role: "owner")
  end

  test "a student drafts, edits, submits, and withdraws a request" do
    sign_in_as users(:student)

    get new_internship_request_path
    assert_response :success
    assert_includes response.body, I18n.t("internship_requests.positionless_notice")

    assert_difference "InternshipRequest.count", 1 do
      post internship_requests_path, params: {
        internship_request: { organization_id: @organization.id, motivation: "Your routing work",
                              learning_goals: "Optimisation" }
      }
    end

    created = InternshipRequest.order(:id).last
    assert_redirected_to internship_request_path(created)
    assert_predicate created, :draft?

    patch internship_request_path(created), params: {
      internship_request: { motivation: "Your routing work, specifically upcountry" }
    }
    assert_equal "Your routing work, specifically upcountry", created.reload.motivation

    assert_difference [ "Notification.count", "AuditEvent.count" ], 1 do
      post submit_internship_request_path(created)
    end
    assert_predicate created.reload, :submitted?

    notification = users(:one).notifications.order(:id).last
    assert_equal "internship_request_received", notification.kind
    assert_equal organization_internship_requests_path(@organization), notification.action_path
    assert_not notification.params.value?("Your routing work, specifically upcountry"),
      "a notification must not copy the request text"

    # A submitted request is no longer the student's to edit.
    get edit_internship_request_path(created)
    assert_redirected_to internship_request_path(created)

    assert_difference "AuditEvent.count", 1 do
      post withdraw_internship_request_path(created)
    end
    assert_predicate created.reload, :withdrawn?
  end

  test "only companies that opted in can be targeted" do
    sign_in_as users(:student)

    get new_internship_request_path
    assert_response :success
    assert_includes response.body, @organization.name
    assert_not_includes response.body, @closed.name

    assert_no_difference "InternshipRequest.count" do
      post internship_requests_path, params: {
        internship_request: { organization_id: @closed.id, motivation: "x", learning_goals: "y" }
      }
    end
    assert_response :not_found
  end

  test "the request surfaces are for students only" do
    [ users(:instructor), users(:admin) ].each do |user|
      sign_in_as user

      get internship_requests_path
      assert_redirected_to root_path, "#{user.name} must not reach the student request surface"

      sign_out
    end
  end

  test "a student cannot read or act on another student's request" do
    request = @organization.internship_requests.create!(student: users(:student), motivation: "Mine",
                                                       learning_goals: "Mine")

    sign_in_as users(:two)

    # The 404 itself is the non-disclosure guarantee: the action raises before
    # rendering, so no view ever sees the record. Asserting against the body
    # would only inspect the test environment's debug page.
    get internship_request_path(request)
    assert_response :not_found

    post submit_internship_request_path(request)
    assert_response :not_found
    assert_predicate request.reload, :draft?

    # The owner of the request does see it, so the 404 above is not a false pass.
    sign_out
    sign_in_as users(:student)
    get internship_request_path(request)
    assert_response :success
    assert_includes response.body, "Mine"
  end

  test "the new-request screen does not exist when no company accepts requests" do
    @organization.update!(accepts_internship_requests: false)
    sign_in_as users(:student)

    get new_internship_request_path
    assert_response :not_found
  end
end
