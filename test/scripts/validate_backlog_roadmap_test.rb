require "test_helper"

require "fileutils"
require "json"
require "open3"
require "tmpdir"

# The gate that reads both files. `script/validate-backlog` is a CI step through
# `bin/docs`, and until 2026-08-12 it held one rule: a milestone whose backlog
# items are all complete must say "Complete" on the roadmap.
#
# That rule was too strong in one direction. Six AI milestones had one complete
# item each, and each item shipped a first slice its own specification calls
# narrower than the milestone — so the check demanded the word "Complete"
# against "Recruiters receive governed assistance across screening and
# coordination" when what exists is an advisory panel. "First slice" is the
# second delivered label, and this file is what keeps both halves of the gate
# honest: the label must still be one of the two when nothing is open, and
# neither of them when something is.
class ValidateBacklogRoadmapTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("script/validate-backlog")

  setup { @directory = Dir.mktmpdir("validate-backlog") }

  teardown { FileUtils.remove_entry(@directory) }

  test "a finished milestone may say Complete" do
    assert_valid roadmap("Complete"), backlog("complete")
  end

  test "a finished milestone may say First slice, because finishing its items is not delivering it" do
    assert_valid roadmap("First slice"), backlog("complete")
    assert_valid roadmap("First slice — increment 1 delivered 2026-08-12 (AI-001)"), backlog("complete")
  end

  test "a finished milestone may not say a planning state" do
    error = assert_invalid roadmap("Proposed"), backlog("complete")

    assert_match(/says "Proposed", but all 1 of its backlog items are complete/, error)
    assert_match(/say "Complete", or "First slice"/, error, "the message has to say what to write instead")
  end

  test "a milestone with open work may claim neither delivered label" do
    %w[ Complete ].each do |label|
      assert_match(/1 backlog item\(s\) are open: AI-001 \(in_progress\)/,
                   assert_invalid(roadmap(label), backlog("in_progress")))
    end

    assert_match(/says "First slice", but 1 backlog item\(s\) are open/,
                 assert_invalid(roadmap("First slice"), backlog("in_progress")))
  end

  # "Firstly" and "First slices" are not the label, and a prefix match without a
  # word boundary would take both.
  test "a word that merely starts like the label is still a disagreement" do
    assert_invalid roadmap("Firstly"), backlog("complete")
  end

  private
    def assert_valid(roadmap, backlog)
      output, status = run_validator(roadmap, backlog)

      assert status.success?, "expected the roadmap to validate, got:\n#{output}"
    end

    def assert_invalid(roadmap, backlog)
      output, status = run_validator(roadmap, backlog)

      assert_not status.success?, "expected a disagreement to be reported, got:\n#{output}"
      output
    end

    def run_validator(roadmap, backlog)
      FileUtils.mkdir_p(File.join(@directory, "docs"))
      File.write(File.join(@directory, "docs/roadmap.md"), roadmap)
      path = File.join(@directory, "docs/backlog.json")
      File.write(path, backlog)

      output, status = Open3.capture2e(SCRIPT.to_s, path)
      [ output, status ]
    end

    # The consolidated table is the one the script reads; `AI M1` maps to the
    # backlog's `AI-M1`.
    def roadmap(label)
      <<~MARKDOWN
        # Product Roadmap

        | Order | Track ID | Milestone | Outcome | Main dependency | Status |
        | ---: | --- | --- | --- | --- | --- |
        | 1 | AI M1 | Foundation | Something smaller than this row claims | None | #{label} |
      MARKDOWN
    end

    def backlog(status)
      JSON.generate(
        schema_version: 1,
        updated_at: "2026-08-12T09:00:00+07:00",
        allowed_statuses: %w[ queued in_progress verification complete blocked ],
        items: [
          { id: "AI-001", title: "One item", status:, priority: 1, owner: "Tech Lead",
            milestone: "AI-M1", updated_at: "2026-08-12T09:00:00+07:00", evidence: [] }
        ],
        updates: []
      )
    end
end
