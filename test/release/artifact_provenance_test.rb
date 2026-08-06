require "test_helper"
require_relative "../../lib/release/artifact"

class ArtifactProvenanceTest < ActiveSupport::TestCase
  def build_artifact(overrides = {})
    Release::Artifact.new(
      image: "ghcr.io/nakasato/utcc-ai-academy",
      digest: "sha256:" + ("a" * 64),
      source_commit: "b" * 40,
      specs: [ "SPEC-0022" ],
      environment: "production",
      sbom: "sbom.cdx.json",
      vulnerability_scan: "trivy.json",
      signature: "cosign:rekor",
      provenance: "github-actions-attestation",
      **overrides
    )
  end

  test "a release manifest identifies the exact image and its evidence" do
    manifest = build_artifact

    assert_equal "ghcr.io/nakasato/utcc-ai-academy@sha256:" + ("a" * 64), manifest.reference
    assert_equal "production", manifest.to_h.fetch("environment")
    assert_equal [ "SPEC-0022" ], manifest.to_h.fetch("specs")
    assert_equal "github-actions-attestation", manifest.to_h.fetch("provenance")
  end

  test "a mutable image tag cannot become a release identity" do
    artifact = build_artifact(image: "ghcr.io/nakasato/utcc-ai-academy:release")

    error = assert_raises(Release::Artifact::Invalid) { artifact.validate! }

    assert_includes error.message, "image must be a registry repository without a tag"
  end

  test "a short commit or non-sha digest cannot pass provenance validation" do
    artifact = build_artifact(source_commit: "c" * 7, digest: "sha256:bad")

    error = assert_raises(Release::Artifact::Invalid) { artifact.validate! }

    assert_includes error.message, "digest must be a sha256 digest"
    assert_includes error.message, "source_commit must be a full Git commit"
  end
end
