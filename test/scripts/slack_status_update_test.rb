require "test_helper"

require "fileutils"
require "json"
require "open3"
require "rbconfig"
require "tmpdir"

class SlackStatusUpdateTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("script/slack-status-update")
  WORKFLOW = Rails.root.join(".github/workflows/ci.yml")

  setup do
    @repository = Dir.mktmpdir("slack-status-update")
    git! "init", "--quiet", "--initial-branch=main"
    git! "config", "user.email", "status-test@example.test"
    git! "config", "user.name", "Status Test"
  end

  teardown { FileUtils.remove_entry(@repository) }

  test "mirrors only the latest appended backlog transition without its title" do
    before = commit(
      "docs/backlog.json" => backlog(
        status: "queued",
        title: "Student student@example.test requested a private change",
        updates: []
      )
    )
    after = commit(
      "docs/backlog.json" => backlog(
        status: "verification",
        title: "Student student@example.test requested a private change",
        updates: [
          update("queued", "in_progress"),
          update("in_progress", "verification")
        ]
      )
    )

    result = run_detector(before, after)
    payload = JSON.generate(result.fetch("payload"))

    assert result.fetch("has_updates")
    assert_includes payload, "SLACK-TEST"
    assert_includes payload, "in_progress"
    assert_includes payload, "verification"
    assert_includes payload, "Platform Owner"
    refute_includes payload, "student@example.test"
    refute_includes payload, "queued"
  end

  test "mirrors a human-owned lifecycle transition such as accepted" do
    before = commit(
      "docs/decisions/adr-0001-example.md" => lifecycle_document(status: "proposed")
    )
    after = commit(
      "docs/decisions/adr-0001-example.md" => lifecycle_document(status: "accepted")
    )

    payload = JSON.generate(run_detector(before, after).fetch("payload"))

    assert_includes payload, "ADR-0001"
    assert_includes payload, "proposed"
    assert_includes payload, "accepted"
    assert_includes payload, "@repository-owner"
    assert_includes payload, "/blob/#{after}/docs/decisions/adr-0001-example.md"
  end

  test "emits no Slack payload when repository status does not change" do
    before = commit("docs/backlog.json" => backlog(status: "queued", updates: []))
    after = commit("README.md" => "No lifecycle transition\n")

    assert_equal({ "has_updates" => false, "payload" => {} }, run_detector(before, after))
  end

  test "rejects a rewritten backlog update history" do
    before = commit(
      "docs/backlog.json" => backlog(
        status: "in_progress",
        updates: [ update("queued", "in_progress") ]
      )
    )
    after = commit(
      "docs/backlog.json" => backlog(
        status: "verification",
        updates: [ update("in_progress", "verification") ]
      )
    )

    _, error, status = detector_command(before, after)

    refute status.success?
    assert_includes error, "updates must remain append-only"
  end

  test "skips an unverifiable completed item without suppressing valid transitions" do
    before = commit(
      "docs/backlog.json" => JSON.pretty_generate("items" => [], "updates" => [])
    )
    after_updates = [
      update("verification", "complete").merge("item_id" => "MISSING-OWNER"),
      update("queued", "verification")
    ]
    after = commit(
      "docs/backlog.json" => backlog(status: "verification", updates: after_updates)
    )

    output, error, status = detector_command(before, after)
    payload = JSON.generate(JSON.parse(output).fetch("payload"))

    assert status.success?
    assert_includes payload, "SLACK-TEST"
    refute_includes payload, "MISSING-OWNER"
    assert_includes error, "no accountable owner"
  end

  test "writes compact outputs for GitHub Actions" do
    before = commit("docs/backlog.json" => backlog(status: "queued", updates: []))
    after = commit(
      "docs/backlog.json" => backlog(
        status: "verification",
        updates: [ update("queued", "verification") ]
      )
    )
    output_path = File.join(@repository, "github-output")

    detector_command(before, after, "--github-output", output_path)
    output = File.read(output_path).lines(chomp: true)

    assert_equal "has_updates=true", output.first
    assert output.second.start_with?("payload={")
    assert_equal 2, output.length
  end

  test "workflow mirrors statuses only after authoritative gates and never makes Slack blocking" do
    workflow = WORKFLOW.read
    job = workflow[/^  notify_status:\n(.*?)^  notify:/m, 1]

    assert job
    assert_includes job, "github.event_name == 'push'"
    assert_includes job, "github.ref == 'refs/heads/main'"
    %w[docs scan_ruby scan_js lint test system-test].each do |required_job|
      assert_includes job, "needs.#{required_job}.result == 'success'"
    end
    assert_equal 2, job.scan("continue-on-error: true").length
    assert_includes job, "vars.SLACK_STATUS_CHANNEL"
    refute_includes job, "vars.SLACK_CI_CHANNEL"
    assert_includes job, "script/slack-status-update"
  end

  private

  def backlog(status:, updates:, title: "Test status item")
    JSON.pretty_generate(
      "items" => [
        {
          "id" => "SLACK-TEST",
          "title" => title,
          "status" => status,
          "owner" => "Platform Owner"
        }
      ],
      "updates" => updates
    )
  end

  def update(from, to)
    {
      "at" => "2026-08-01T00:00:00+07:00",
      "item_id" => "SLACK-TEST",
      "from" => from,
      "to" => to,
      "summary" => "Status changed"
    }
  end

  def lifecycle_document(status:)
    <<~MARKDOWN
      ---
      id: ADR-0001
      type: adr
      title: Example decision
      status: #{status}
      owners: ["@repository-owner"]
      ---

      # Example
    MARKDOWN
  end

  def commit(files)
    files.each do |path, content|
      absolute_path = File.join(@repository, path)
      FileUtils.mkdir_p(File.dirname(absolute_path))
      File.write(absolute_path, content)
    end
    git! "add", "."
    git! "commit", "--quiet", "--message", "test fixture"
    git!("rev-parse", "HEAD").strip
  end

  def run_detector(before, after)
    output, error, status = detector_command(before, after)
    assert status.success?, error
    JSON.parse(output)
  end

  def detector_command(before, after, *additional_arguments)
    Open3.capture3(
      RbConfig.ruby,
      SCRIPT.to_s,
      "--root", @repository,
      "--before", before,
      "--after", after,
      "--channel", "C0123456789",
      "--repository-url", "https://github.com/example/project",
      "--run-url", "https://github.com/example/project/actions/runs/1",
      *additional_arguments
    )
  end

  def git!(*arguments)
    output, error, status = Open3.capture3("git", *arguments, chdir: @repository)
    assert status.success?, error
    output
  end
end
