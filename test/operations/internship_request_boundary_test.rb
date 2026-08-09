require "test_helper"

class InternshipRequestBoundaryTest < ActiveSupport::TestCase
  ROOT = Rails.root

  test "the recorded increment-1 decisions still govern the implementation" do
    adr = ROOT.join("docs/decisions/adr-0041-student-internship-request-boundary.md").read
    spec = ROOT.join("docs/specs/spec-student-internship-requests.md").read

    assert_includes adr, "## Recorded decisions (2026-08-09, increment 1)"
    assert_includes adr, "## Human decisions still required"
    refute_includes spec, "implemented_by: []",
      "SPEC-0041 must list the files that implement the authorized increment"
  end

  test "a request is strictly position-less, so no second application model appears" do
    assert_not_includes InternshipRequest.column_names, "program_id",
      "a program column would make this a second Recruitment::InternshipApplication"
    assert_not_includes InternshipRequest.reflect_on_all_associations.map(&:name), :program

    refute_match(/belongs_to :program\b/, code_of("app/models/internship_request.rb"))
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
  end

  test "no deferred increment ships before its own decision is recorded" do
    refute ROOT.join("app/models/internship_faculty_assignment.rb").exist?,
      "faculty oversight needs ADR-0041 decision 2 from the Academic Owner first"

    routes = internship_request_routes
    %w[faculty academic_review].each do |word|
      refute_includes routes, word, "a #{word} route implies a deferred increment shipped early"
    end
  end

  test "a placement never writes to the recruitment application it may originate from" do
    placement = code_of("app/models/internship_placement.rb")

    assert_includes placement, "belongs_to :application",
      "increment 2 accepts an accepted recruitment application as an origin"
    refute_match(/application\.update|application\.transition_to|application\.accept!|application\.reject!/,
                 placement,
                 "SPEC-0028 owns the application; a placement references it read-only")

    report = code_of("app/models/internship_progress_report.rb")
    refute_match(/\bcredit\b|\bgrade\b|\bgpa\b/i, report,
      "hours are evidence for a supervisor, never converted to credit or a grade")
  end

  test "no document, mailer, api, or academic-credit surface exists" do
    routes = internship_request_routes
    %w[attachment document upload resume portfolio].each do |word|
      refute_includes routes, word,
        "an internship-request #{word} route implies uploads before the document contract exists"
    end
    refute_includes routes, "namespace :api"
    refute_includes routes, "format: :json"

    model = code_of("app/models/internship_request.rb")
    refute_match(/has_one_attached|has_many_attached/, model)
    %w[credit grade hours].each do |word|
      assert_not_includes InternshipRequest.column_names, word,
        "increment 1 holds no #{word} column; academic consequences are an institutional decision"
    end
    refute_match(/\bcredit\b|\bgrade\b/i, model,
      "increment 1 records no academic credit or grade")

    Dir[ROOT.join("app/mailers/**/*.rb")].each do |mailer_path|
      refute_includes File.read(mailer_path), "internship_request",
        "#{mailer_path} implies internship-request email; ADR-0004 defers the production email provider"
    end
  end

  private
    # Comments explain the boundary and naturally name the very things the
    # boundary forbids, so every check reads code with the prose stripped out.
    def code_of(path)
      ROOT.join(path).read.lines.reject { |line| line.strip.start_with?("#") }.join
    end

    def internship_request_routes
      block = ROOT.join("config/routes.rb").read[/# Internship requests.*?# End internship requests/m].to_s
      assert block.present?, "the internship-request route block must be delimited for this boundary check"
      block.lines.reject { |line| line.strip.start_with?("#") }.join
    end
end
