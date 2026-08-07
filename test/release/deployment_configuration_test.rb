require "test_helper"
require "yaml"

class DeploymentConfigurationTest < ActiveSupport::TestCase
  ROOT = Rails.root

  setup do
    @service = YAML.load_file(ROOT.join("render.yaml")).fetch("services").fetch(0)
  end

  test "Render is the Singapore production target with an image-backed service" do
    assert_equal "web", @service.fetch("type")
    assert_equal "image", @service.fetch("runtime")
    assert_equal "singapore", @service.fetch("region")
    assert_equal [ "academy.boring9.dev" ], @service.fetch("domains")
    assert_equal "/up", @service.fetch("healthCheckPath")
    assert_equal "bin/rails db:migrate", @service.fetch("preDeployCommand")
  end

  test "Render references the private registry without embedding credentials" do
    image = @service.fetch("image")

    assert_equal "ghcr.io/nakasato/utcc-ai-academy:release", image.fetch("url")
    assert_equal "utcc-ai-academy-ghcr", image.dig("creds", "fromRegistryCreds", "name")
    refute_match(/latest|localhost|example\.com|192\.168\./, image.fetch("url"))
    assert_nil image.dig("creds", "password")
  end

  test "the Render service preserves local Active Storage on an explicit disk" do
    disk = @service.fetch("disk")

    assert_equal "/rails/storage", disk.fetch("mountPath")
    assert_operator disk.fetch("sizeGB"), :>, 0
    assert_equal 1, @service.fetch("numInstances")
  end

  test "production secrets are dashboard-owned and Mailpit is not a production variable" do
    variables = @service.fetch("envVars").to_h { |variable| [ variable.fetch("key"), variable ] }

    assert_equal false, variables.fetch("RAILS_MASTER_KEY").fetch("sync")
    assert_equal false, variables.fetch("DATABASE_URL").fetch("sync")
    refute variables.key?("SMTP_HOST")
    refute variables.key?("MAILPIT_HOST")
  end

  test "the manual deploy workflow requires an immutable image digest" do
    workflow = ROOT.join(".github/workflows/render-deploy.yml").read

    assert_includes workflow, "image_digest"
    assert_includes workflow, "sha256"
    assert_includes workflow, "RENDER_DEPLOY_HOOK_URL"
    assert_includes workflow, "environment: production"
  end
end
