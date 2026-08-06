require "test_helper"
require "date"
require "yaml"

class ReleaseGateTest < ActiveSupport::TestCase
  ROOT = Rails.root

  test "the Render release record is planned and names the safety evidence" do
    path = ROOT.join("docs/releases/release-render-production-boundary.md")
    body = path.read
    metadata = YAML.safe_load(
      body[/\A---\s*\n(.*?)\n---\s*\n/m, 1],
      permitted_classes: [ Date ],
      aliases: false
    )

    assert_equal "REL-2026-08-06", metadata.fetch("id")
    assert_equal "planned", metadata.fetch("status")
    assert_equal "C", metadata.fetch("risk_tier")
    assert_equal "rolling", metadata.fetch("deploy_strategy")
    assert_includes body, "Expand"
    assert_includes body, "Render rollback"
    assert_includes body, "/up"
    assert_includes body, "Mailpit"
    assert_includes body, "backup and restore"
  end

  test "the deployment runbook is linked to the release and recovery contracts" do
    body = ROOT.join("docs/runbooks/rb-render-deployment.md").read

    assert_includes body, "ADR-0020"
    assert_includes body, "ADR-0021"
    assert_includes body, "SPEC-0022"
    assert_includes body, "Render"
    assert_includes body, "sha256"
    assert_includes body, "bin/rails db:migrate"
  end
end
