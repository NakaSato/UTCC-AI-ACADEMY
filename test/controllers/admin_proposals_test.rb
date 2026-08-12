require "test_helper"

# The Proposals tab: the one screen on which somebody other than an author reads
# a proposal, and the only place one can be answered. SPEC-0050.
class AdminProposalsTest < ActionDispatch::IntegrationTest
  setup do
    @proposal = ProposalRequest.create!(
      user: users(:one),
      title: "Weekly project clinic",
      category: "feature",
      problem: "Learners need a place to unblock their projects.",
      idea: "Add a weekly session with a contributor and a shared queue.",
      impact: "Projects move forward with less waiting."
    )
  end

  test "the tab lists a proposal with its author and a form to answer it" do
    sign_in_as users(:admin)
    get admin_url(tab: :proposals)

    assert_response :success
    assert_select "nav a[aria-current=page]", text: /#{Regexp.escape(I18n.t("admin.tabs.proposals"))}/
    assert_select "[data-proposal-id=?]", @proposal.id.to_s
    assert_select "main", text: /#{Regexp.escape(@proposal.reference)}/
    assert_select "main", text: /#{Regexp.escape(users(:one).name)}/
    assert_select "form[action=?]", admin_proposal_decision_path(@proposal)
  end

  test "the tab badge counts what is waiting on an administrator" do
    assert_equal ProposalRequest.undecided.count, AdminConsole.badge_for(:proposals)
    assert_equal 1, AdminConsole.badge_for(:proposals)

    @proposal.decide!(actor: users(:admin), to_status: "declined", reason: "Not this term.")

    assert_equal 0, AdminConsole.badge_for(:proposals)
  end

  # The counter is a Vue island (ADR-0051) and the browser is what proves it
  # counts. What the server owns is the half a browser cannot fix: the island
  # names a field id that exists on this page, its limit matches the field's own
  # `maxlength`, and the copy comes from the locale files with `%{count}` still
  # in it for the island to fill. A drift in any of those is a counter that
  # silently counts nothing.
  test "the reason field carries a counter island bound to itself" do
    sign_in_as users(:admin)
    get admin_url(tab: :proposals)

    field = css_select("input#proposal_#{@proposal.id}_reason").first

    assert_not_nil field, "the reason field must carry the id the island is given"
    assert_equal "1000", field["maxlength"]

    island = css_select("[data-vue-island]").first
    props = JSON.parse(island["data-vue-island-props"])

    assert_equal "character-counter", island["data-vue-island"]
    assert_equal field["id"], props["fieldId"]
    assert_equal field["maxlength"].to_i, props["max"]
    assert_equal I18n.t("forms.characters_left"), props["template"]
    assert_includes props["template"], "%{count}", "the island interpolates the number the server does not have"
  end

  test "an administrator answers a proposal and the reason is recorded with it" do
    sign_in_as users(:admin)

    assert_difference "ProposalDecision.count", 1 do
      post admin_proposal_decision_path(@proposal),
           params: { status: "planned", reason: "Scheduled for the next increment." }
    end

    assert_redirected_to admin_path(tab: :proposals)
    assert_equal I18n.t("flash.proposal_decided", reference: @proposal.reference), flash[:notice]
    assert_equal "planned", @proposal.reload.status
    assert_equal "Scheduled for the next increment.", @proposal.latest_decision.reason
    assert_equal users(:admin), @proposal.latest_decision.actor
  end

  # A privilege-shaped action: it speaks to a student in the platform's name and
  # cannot be undone from the screen that did it.
  test "answering a proposal is audited at warning level without the author's reason" do
    sign_in_as users(:admin)
    post admin_proposal_decision_path(@proposal),
         params: { status: "in_review", reason: "Reading it this week." }

    event = AuditEvent.newest_first.first
    assert_equal "proposal_decided", event.action
    assert_equal :warn, event.level
    assert_equal users(:admin), event.user
    assert_includes event.text, @proposal.reference
    assert_not_includes event.text, "Reading it this week."
  end

  test "a decision without a reason is refused and writes nothing" do
    sign_in_as users(:admin)

    assert_no_difference "ProposalDecision.count" do
      post admin_proposal_decision_path(@proposal), params: { status: "planned", reason: "  " }
    end

    assert_redirected_to admin_path(tab: :proposals)
    assert_equal I18n.t("flash.proposal_decision_invalid"), flash[:alert]
    assert_equal "submitted", @proposal.reload.status
  end

  test "an answered proposal offers no form and refuses a second decision" do
    @proposal.decide!(actor: users(:admin), to_status: "planned", reason: "Scheduled.")
    sign_in_as users(:admin)

    get admin_url(tab: :proposals)
    assert_select "form[action=?]", admin_proposal_decision_path(@proposal), 0
    assert_select "main", text: /#{Regexp.escape(I18n.t("admin.proposals.answered"))}/

    assert_no_difference "ProposalDecision.count" do
      post admin_proposal_decision_path(@proposal), params: { status: "declined", reason: "Changed our minds." }
    end

    assert_equal I18n.t("flash.proposal_decision_invalid"), flash[:alert]
    assert_equal "planned", @proposal.reload.status
  end

  # The console is admin-only, and a proposal's own author is a student or an
  # instructor — which is exactly why ADR-0049 refused the instructor workspace.
  test "nobody but an administrator reaches the tab or the decision" do
    [ users(:one), users(:instructor) ].each do |actor|
      sign_in_as actor

      get admin_url(tab: :proposals)
      assert_redirected_to root_path
      assert_equal I18n.t("flash.forbidden"), flash[:alert]

      assert_no_difference "ProposalDecision.count" do
        post admin_proposal_decision_path(@proposal), params: { status: "planned", reason: "Mine now." }
      end
      assert_equal "submitted", @proposal.reload.status
    end
  end
end
