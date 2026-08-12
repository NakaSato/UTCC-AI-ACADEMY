require "application_system_test_case"

# The first Vue island, and the half no other test can see (ADR-0051, SPEC-0052).
#
# Everything the server owns is asserted in `admin_proposals_test.rb`: that the
# island names a field on the page, with the limit that field enforces, and the
# copy from the locale files. None of that proves the island mounts. Three of
# the ways it could fail are visible only in a browser:
#
#   - the CSP blocks it, which is what the full Vue build would do;
#   - it never mounts, because the registry, the pin or the bridge is wrong;
#   - it mounts and then does not react, or reacts to the wrong field.
class VueIslandWalkTest < ApplicationSystemTestCase
  test "the counter mounts, counts down as an administrator types, and warns near the limit" do
    ProposalRequest.create!(user: users(:one), title: "Weekly project clinic", category: "feature",
                            problem: "Learners need somewhere to unblock their projects.",
                            idea: "A weekly session with a contributor and a shared queue.",
                            impact: "Projects move forward with less waiting.")

    sign_in_through_the_form(users(:admin))
    visit admin_path(tab: :proposals)

    counter = find("[data-vue-island] p")
    field = find("input[id$=_reason]")

    # Mounted, and counting the empty field rather than nothing.
    assert_equal I18n.t("forms.characters_left", locale: :th).sub("%{count}", "1000"), counter.text

    field.send_keys("สั้น")

    assert_selector "[data-vue-island] p",
                    text: I18n.t("forms.characters_left", locale: :th).sub("%{count}", "996")

    # Near the limit the line changes tone, which is the only thing the island
    # decides for itself.
    assert_no_selector "[data-vue-island] p.text-gold-ink"
    field.send_keys("x" * 901)

    assert_selector "[data-vue-island] p.text-gold-ink"
  end

  # An island is an enhancement over markup that already works (SPEC-0052 rule
  # 3), and the form is the part that must not depend on it.
  test "the reason still submits with the island present" do
    proposal = ProposalRequest.create!(user: users(:one), title: "Second clinic", category: "feature",
                                       problem: "A problem worth stating.", idea: "An idea worth reading.",
                                       impact: "An outcome worth having.")

    sign_in_through_the_form(users(:admin))
    visit admin_path(tab: :proposals)

    find("input[id$=_reason]").send_keys("รับไว้พิจารณาในรอบถัดไป")
    find("input[type=submit][value='#{I18n.t("admin.proposals.record", locale: :th)}']").click

    # A redirect, so the flash rather than a toast — the decision is recorded on
    # the server and the island had nothing to do with it, which is the point.
    assert_selector "[role=status]",
                    text: I18n.t("flash.proposal_decided", reference: proposal.reference, locale: :th), wait: 10
    assert_equal "รับไว้พิจารณาในรอบถัดไป", proposal.reload.latest_decision.reason
  end
end
