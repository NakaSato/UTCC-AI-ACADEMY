require "test_helper"

class BusinessCaseGateTest < ActiveSupport::TestCase
  ROOT = Rails.root

  test "the accepted business-case design gate still authorizes no implementation" do
    spec = ROOT.join("docs/specs/spec-company-business-case-collaboration.md").read

    assert_includes spec, "authorizes no\n> business-case route"
    assert_includes spec, "## Human review handoff"
    assert_includes spec, "implemented_by: []"
  end

  test "no business-case route or model ships before the review handoff is recorded" do
    refute ROOT.join("app/models/business_case.rb").exist?,
      "a BusinessCase model implies implementation; SPEC-0040's review handoff must be recorded first"
    refute_includes ROOT.join("config/routes.rb").read, "business_case"
  end
end
