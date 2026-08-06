require "json"

module Release
  class Artifact
    SHA256_DIGEST = /\Asha256:[0-9a-f]{64}\z/
    GIT_COMMIT = /\A[0-9a-f]{40}\z/

    class Invalid < StandardError; end

    REQUIRED_FIELDS = %i[
      image digest source_commit specs environment sbom vulnerability_scan
      signature provenance
    ].freeze

    attr_reader(*REQUIRED_FIELDS)

    def initialize(image:, digest:, source_commit:, specs:, environment:, sbom:, vulnerability_scan:, signature:, provenance:)
      @image = image
      @digest = digest
      @source_commit = source_commit
      @specs = specs
      @environment = environment
      @sbom = sbom
      @vulnerability_scan = vulnerability_scan
      @signature = signature
      @provenance = provenance
    end

    def validate!
      errors = []
      errors << "image must be a registry repository without a tag" unless image.is_a?(String) && image.match?(%r{\A[a-z0-9./_-]+\z}) && !image.include?(":")
      errors << "digest must be a sha256 digest" unless digest.is_a?(String) && digest.match?(SHA256_DIGEST)
      errors << "source_commit must be a full Git commit" unless source_commit.is_a?(String) && source_commit.match?(GIT_COMMIT)
      errors << "specs must contain at least one specification" unless specs.is_a?(Array) && specs.any? { |spec| spec.is_a?(String) && !spec.empty? }
      errors << "environment must be production" unless environment == "production"

      REQUIRED_FIELDS.each do |field|
        value = public_send(field)
        errors << "#{field} must be present" if value.nil? || (value.respond_to?(:empty?) && value.empty?)
      end

      raise Invalid, errors.join("; ") unless errors.empty?

      self
    end

    def reference
      validate!
      "#{image}@#{digest}"
    end

    def to_h
      validate!
      REQUIRED_FIELDS.to_h { |field| [ field.to_s, public_send(field) ] }.merge("reference" => reference)
    end

    def to_json(*)
      JSON.generate(to_h)
    end
  end
end
