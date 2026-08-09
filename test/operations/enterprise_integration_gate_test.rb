require "test_helper"

class EnterpriseIntegrationGateTest < ActiveSupport::TestCase
  ROOT = Rails.root

  test "the accepted integration design gate still authorizes no external exchange" do
    spec = ROOT.join("docs/specs/spec-recruitment-enterprise-integrations.md").read

    assert_includes spec, "authorizes no external request"
    assert_includes spec, "## Human review handoff"
    assert_includes spec, "implemented_by: []"
  end

  test "no integration provider dependency ships before the review handoff is recorded" do
    lockfile = ROOT.join("Gemfile.lock").read

    %w[omniauth ruby-saml oauth2 scim_rails icalendar].each do |gem_name|
      refute_match(/^    #{Regexp.escape(gem_name)} /, lockfile,
        "#{gem_name} implies an integration connector; SPEC-0039's review handoff must be recorded first")
    end
  end
end
