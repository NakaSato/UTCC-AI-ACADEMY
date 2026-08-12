require "test_helper"

class ContributorsTest < ActionDispatch::IntegrationTest
  test "the contributor presentation is public and complete in both locales" do
    sign_out

    %w[th en].each do |locale|
      post language_path(locale)
      get contributors_path

      assert_response :success
      assert_select "main#main", 1
      assert_select "h1", text: I18n.t("contributors.hero_title", locale:)
      assert_select "section#story", 1
      assert_select "section#contributors", 1
      assert_select "section#contributors article", 4
      assert_select "section#practice", 1
      assert_select "a[href=?]", new_proposal_request_path, 1
      refute_includes response.body, "translation missing"
    end
  end

  test "the public page does not expose private candidate profile routes" do
    sign_out
    get contributors_path

    assert_response :success
    assert_select "a[href=?]", edit_recruitment_candidate_profile_path, 0
    assert_select "a[href=?]", recruitment_candidate_profile_export_path, 0
  end

  test "the contributor page reuses the landing page navbar" do
    sign_out
    get contributors_path

    assert_select "header a", text: I18n.t("landing.nav.learn"), count: 2
    assert_select "header a[href=?]", "#{root_path}#learn", 2
    assert_select "header a[href='#story']", 0
  end

  test "a signed-in contributor can view the proposal form" do
    sign_in_as users(:one)
    get new_proposal_request_path

    assert_response :success
    assert_select "h1", text: I18n.t("proposal_request.new_title")
    assert_select "form[action=?][method=post]", proposal_requests_path, 1
    assert_select "[name='proposal_request[title]']", 1
    assert_select "[name='proposal_request[problem]']", 1
    assert_select "[name='proposal_request[idea]']", 1
    assert_select "[name='proposal_request[impact]']", 1
  end

  test "a signed-in contributor can submit and view a proposal confirmation" do
    sign_in_as users(:one)

    assert_difference "ProposalRequest.count", 1 do
      post proposal_requests_path, params: {
        proposal_request: {
          title: "Weekly project clinic",
          category: "feature",
          problem: "Learners need a place to unblock their projects.",
          idea: "Add a weekly session with a contributor and a shared queue.",
          impact: "Projects move forward with less waiting."
        }
      }
    end

    proposal = ProposalRequest.order(:id).last
    assert_redirected_to proposal_request_path(proposal)

    follow_redirect!

    assert_response :success
    assert_select "h1", text: I18n.t("proposal_request.confirmation_title")
    assert_includes response.body, proposal.reference
  end

  # The whole of the explanation M13 promises, read where ADR-0049 decision 4
  # said it would be: on the page the author already has, at their next visit.
  # Before SPEC-0050 this page rendered a status that could never move.
  test "an author reads the decision and the reason on their own proposal" do
    proposal = ProposalRequest.create!(
      user: users(:one), title: "Weekly project clinic", category: "feature",
      problem: "Learners need a place to unblock their projects.",
      idea: "Add a weekly session with a contributor and a shared queue.",
      impact: "Projects move forward with less waiting."
    )
    sign_in_as users(:one)

    get proposal_request_path(proposal)
    assert_response :success
    assert_includes response.body, I18n.t("proposal_request.status.submitted")
    assert_not_includes response.body, I18n.t("proposal_request.decision.heading")

    proposal.decide!(actor: users(:admin), to_status: "planned",
                     reason: "Scheduled for the next increment.")
    get proposal_request_path(proposal)

    assert_response :success
    assert_includes response.body, I18n.t("proposal_request.status.planned")
    assert_includes response.body, I18n.t("proposal_request.decision.heading")
    assert_includes response.body, "Scheduled for the next increment."
  end

  # Only the current answer. An author is not shown the console's working out.
  test "an author reads the latest reason and not the ones before it" do
    proposal = ProposalRequest.create!(
      user: users(:one), title: "Weekly project clinic", category: "feature",
      problem: "Learners need a place to unblock their projects.",
      idea: "Add a weekly session with a contributor and a shared queue.",
      impact: "Projects move forward with less waiting."
    )
    proposal.decide!(actor: users(:admin), to_status: "in_review", reason: "Reading it this week.")
    proposal.decide!(actor: users(:admin), to_status: "declined", reason: "Not this term, sorry.")
    sign_in_as users(:one)

    get proposal_request_path(proposal)

    assert_response :success
    assert_includes response.body, "Not this term, sorry."
    assert_not_includes response.body, "Reading it this week."
  end

  test "the proposal form requires authentication" do
    sign_out
    get new_proposal_request_path

    assert_redirected_to login_path
    assert_equal I18n.t("flash.sign_in_required"), flash[:alert]
  end

  test "a signed-out proposal link returns to the form after login" do
    sign_out
    get new_proposal_request_path

    assert_redirected_to login_path

    post login_path, params: { student_id: users(:one).student_id, password: "password" }

    assert_redirected_to new_proposal_request_path
  end

  # SPEC-0049 records the intake as built, and recording it showed that its two
  # refusals were the two things nothing asserted. Both are one line of
  # controller each, which is exactly how they would be lost.
  test "an author cannot read another contributor's proposal" do
    proposal = ProposalRequest.create!(
      user: users(:one),
      title: "Weekly project clinic",
      category: "feature",
      problem: "Learners need a place to unblock their projects.",
      idea: "Add a weekly session with a contributor and a shared queue.",
      impact: "Projects move forward with less waiting."
    )

    sign_in_as users(:two)
    get proposal_request_path(proposal)

    assert_response :not_found
  end

  test "an incomplete proposal re-renders the form and writes nothing" do
    sign_in_as users(:one)

    assert_no_difference "ProposalRequest.count" do
      post proposal_requests_path, params: {
        proposal_request: {
          title: "   ",
          category: "feature",
          problem: "Learners need a place to unblock their projects.",
          idea: "Add a weekly session with a contributor and a shared queue.",
          impact: "Projects move forward with less waiting."
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "form[action=?]", proposal_requests_path, 1
  end

  # The model refuses a non-contributor and so does the controller. The model
  # rule is the one with a test; this is the door. A signed-in account with the
  # wrong role is sent to root with the forbidden flash rather than refused
  # outright — see Authorization#authorize_role, where both denials land there.
  test "a staff account cannot reach the proposal form" do
    sign_in_as users(:admin)
    get new_proposal_request_path

    assert_redirected_to root_path
    assert_equal I18n.t("flash.forbidden"), flash[:alert]
  end
end
