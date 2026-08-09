require "test_helper"

class BusinessCaseBoundaryTest < ActiveSupport::TestCase
  ROOT = Rails.root

  test "the recorded Phase 1 handoff decisions still govern the implementation" do
    spec = ROOT.join("docs/specs/spec-company-business-case-collaboration.md").read

    assert_includes spec, "### Recorded decisions (2026-08-09, Phase 1)"
    assert_includes spec, "## Human review handoff"
    refute_includes spec, "implemented_by: []",
      "SPEC-0040 must list the files that implement the authorized slice"
  end

  test "no business-case upload surface ships before the asset contract is approved" do
    business_case_routes = ROOT.join("config/routes.rb").read[/# Business-case collaboration.*?# End business-case collaboration/m].to_s
    assert business_case_routes.present?, "the business-case route block must be delimited for this boundary check"

    %w[attachment asset upload].each do |word|
      refute_includes business_case_routes, word,
        "a business-case #{word} route implies an upload surface; SPEC-0040's asset decisions must be recorded first"
    end

    Dir[ROOT.join("app/models/business_case*.rb")].each do |model_path|
      model = File.read(model_path)
      refute_match(/has_one_attached|has_many_attached/, model,
        "#{model_path} attaches files; SPEC-0040's asset decisions must be recorded first")
    end
  end

  test "no business-case mailer or API ships before their review decisions are recorded" do
    Dir[ROOT.join("app/mailers/**/*.rb")].each do |mailer_path|
      refute_includes File.read(mailer_path), "business_case",
        "#{mailer_path} implies business-case email; ADR-0004 defers the production email provider"
    end

    business_case_routes = ROOT.join("config/routes.rb").read[/# Business-case collaboration.*?# End business-case collaboration/m].to_s
    refute_includes business_case_routes, "namespace :api"
    refute_includes business_case_routes, "format: :json"
  end
end
