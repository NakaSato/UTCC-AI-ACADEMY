require "test_helper"

class InternshipRequestGateTest < ActiveSupport::TestCase
  ROOT = Rails.root

  test "the internship-request design gate still authorizes no implementation" do
    spec = ROOT.join("docs/specs/spec-student-internship-requests.md").read

    assert_includes spec, "authorizes no internship-request route"
    assert_includes spec, "## Human review handoff"
    assert_includes spec, "implemented_by: []"
  end

  test "no internship-request or placement model ships before the review handoff is recorded" do
    %w[
      app/models/internship_request.rb
      app/models/internship_placement.rb
      app/models/internship_progress_report.rb
    ].each do |path|
      refute ROOT.join(path).exist?,
        "#{path} implies implementation; SPEC-0041's review handoff must be recorded first"
    end

    routes = ROOT.join("config/routes.rb").read

    refute_includes routes, "internship_request"
    refute_includes routes, "internship-request"
    refute_includes routes, "internship_placement"
  end

  test "the shipped internship domain remains the single owner of positions and applications" do
    %w[
      app/models/recruitment/internship_program.rb
      app/models/recruitment/internship_application.rb
      app/models/recruitment/internship_evaluation.rb
    ].each do |path|
      assert ROOT.join(path).exist?,
        "SPEC-0041 draws its boundary against #{path}; the boundary is meaningless if it disappears"
    end

    # A second position or application model would be the duplication ADR-0041
    # exists to prevent, whatever it ends up being called.
    Dir[ROOT.join("app/models/internship_*.rb")].each do |path|
      flunk "#{path} adds an internship model outside the Recruitment namespace before SPEC-0041 is accepted"
    end
  end
end
