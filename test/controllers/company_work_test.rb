require "test_helper"

# The company workspace's front door. ADR-0048: `/` lands a company member on
# the work waiting for them, the slug root keeps being the company's record, and
# the board is the same for every active member.
class CompanyWorkTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "North Star", creator: users(:admin),
                                         accepts_internship_requests: true)
    @owner = users(:console_company)
    @organization.memberships.create!(user: @owner, role: "owner")
  end

  test "a member of one company lands on its work surface" do
    sign_in_as @owner
    get root_path

    assert_redirected_to work_company_path(@organization)
  end

  test "a member of two companies still lands on the chooser" do
    second = Organization.create!(name: "South Cross", creator: users(:admin))
    second.memberships.create!(user: @owner, role: "recruiter")

    sign_in_as @owner
    get root_path

    assert_redirected_to companies_path
  end

  test "the work surface opens at the company's name" do
    sign_in_as @owner
    get work_company_path(@organization)

    assert_response :success
    assert_equal "/company/north-star/work", work_company_path(@organization)
    assert_select "h1", I18n.t("recruitment.company_work.title")
  end

  test "the company record is still its own screen" do
    sign_in_as @owner
    get company_path(@organization)

    assert_response :success
    assert_select "h1", "North Star"
  end

  test "an outsider cannot open a company's work surface" do
    sign_in_as users(:two)
    get work_company_path(@organization)

    assert_response :not_found
  end

  test "an administrator may open any active company's work surface" do
    sign_in_as users(:admin)
    get work_company_path(@organization)

    assert_response :success
  end

  # Invariant 4: a suspended company is not operating, so there is no board for
  # it — the same answer its other screens give a member. That was aspirational
  # when it was written: the record screen served one until 2026-08-12. See
  # ADR-0048 decision 7, where the administrator exception is recorded too.
  test "a suspended company has no work surface" do
    @organization.update!(status: "suspended")

    sign_in_as @owner
    get work_company_path(@organization)

    assert_response :not_found
  end

  test "a signed-out visitor is sent to the front door" do
    get work_company_path(@organization)

    assert_redirected_to root_path
  end

  # Invariant 5: counts and links, never a name or a sentence a student wrote.
  test "waiting work is counted and linked, and no student data is printed" do
    request = @organization.internship_requests.create!(student: users(:student),
                                                        motivation: "Your routing work is why I applied",
                                                        learning_goals: "Optimisation")
    request.submit!(actor: users(:student))

    sign_in_as @owner
    get work_company_path(@organization)

    assert_response :success
    assert_select "a[href=?]", company_internship_requests_path(@organization)
    assert_select "body" do |body|
      assert_no_match(/Your routing work is why I applied/, body.first.to_s)
      assert_no_match(/#{users(:student).name}/, body.first.to_s)
    end
  end

  # A running internship is not work waiting on anybody, and it has its own card
  # under "what is running". It was in the waiting grid too, whenever the count
  # was non-zero, asking for a note nobody had written for it — so a company with
  # an active placement met "translation missing" on its own front door, in both
  # languages, while every test here ran against a company that had none.
  #
  # Rendered in both locales because that is where it showed: `t` falls back to
  # English, and the key was missing from English as well.
  test "an active placement is counted as running rather than waiting" do
    placement = active_placement

    I18n.available_locales.each do |locale|
      sign_in_as @owner
      get work_company_path(@organization, lang: locale)

      assert_response :success
      assert_select "body" do |body|
        assert_no_match(/translation missing/i, body.first.to_s, "#{locale} is missing copy this screen asks for")
      end
      assert_select "h2", text: I18n.t("recruitment.company_work.running.title", locale: locale)
      # One card for it, under "running" — not a second one in the waiting grid.
      assert_select "a[href=?]", internship_placements_path, minimum: 1
    end

    assert_predicate placement, :active?
  end

  # ADR-0048 decision 4 shows every active member the whole board, and SPEC-0041
  # gives the request queue to deciders alone — an administrator included, whose
  # read there is "a placement record, to assign or revoke its supervisor" and
  # nothing wider. Both rules are right; the link between them was not. A mentor
  # and an administrator each saw a card linking to a queue that answered them
  # 404, on a screen they are meant to be on.
  #
  # So the count stays and the link goes, for exactly the readers who are refused.
  test "a queue nobody may open is counted without a link to it" do
    request = @organization.internship_requests.create!(student: users(:student),
                                                        motivation: "Routing", learning_goals: "Measuring")
    request.submit!(actor: users(:student))
    mentor = users(:instructor)
    @organization.memberships.create!(user: mentor, role: "mentor")

    [ mentor, users(:admin) ].each do |refused|
      sign_in_as refused
      get work_company_path(@organization)

      assert_response :success
      assert_select "main", text: /#{I18n.t("recruitment.company_work.queues.internship_requests")}/,
        message: "the count is the point of the board — it must still be there"
      assert_select "a[href=?]", company_internship_requests_path(@organization), count: 0,
        message: "a link this reader is answered 404 at"

      get company_internship_requests_path(@organization)
      assert_response :not_found, "and the queue itself still refuses them"
    end

    sign_in_as @owner
    get work_company_path(@organization)

    assert_select "a[href=?]", company_internship_requests_path(@organization),
      message: "a decider must still be able to open it"
  end

  test "a company with nothing waiting says so rather than showing zeroes" do
    sign_in_as @owner
    get work_company_path(@organization)

    assert_response :success
    assert_select "p", I18n.t("recruitment.company_work.waiting.empty_title")
  end

  # Decision 5: no reporter role, no application figures — and the rest of the
  # board still renders.
  test "a member outside the reporter roles sees no application figures" do
    mentor = users(:instructor)
    @organization.memberships.create!(user: mentor, role: "mentor")

    sign_in_as mentor
    get work_company_path(@organization)

    assert_response :success
    assert_select "h2", { text: I18n.t("recruitment.company_work.applications.title"), count: 0 }
    assert_select "h2", text: I18n.t("recruitment.company_work.running.title")
  end

  test "the company navigation leads with the work surface" do
    sign_in_as @owner
    get work_company_path(@organization)

    assert_response :success
    assert_select "a", text: I18n.t("chrome.nav.work")
  end

  private
    # A placement the company is actually hosting: a request, approved, turned
    # into a placement and activated — the same route the seeds take.
    def active_placement
      request = @organization.internship_requests.create!(student: users(:student),
                                                          motivation: "Routing", learning_goals: "Measuring")
      request.submit!(actor: users(:student))
      request.approve!(actor: @owner)
      InternshipPlacement.from_request!(request, actor: @owner).tap { it.activate!(actor: @owner) }
    end
end
