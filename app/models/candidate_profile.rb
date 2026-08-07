class CandidateProfile < ApplicationRecord
  VISIBILITIES = %w[ private application_only searchable ].freeze
  URL_FIELDS = %i[ portfolio_url github_url linkedin_url ].freeze
  MAX_ATTACHMENT_BYTES = 10.megabytes
  RESUME_CONTENT_TYPES = %w[ text/plain application/pdf application/msword
                              application/vnd.openxmlformats-officedocument.wordprocessingml.document ].freeze
  PORTFOLIO_CONTENT_TYPES = %w[ application/pdf image/png image/jpeg image/webp ].freeze

  belongs_to :user, inverse_of: :candidate_profile
  has_many :facts, class_name: "CandidateProfileFact", dependent: :destroy, inverse_of: :candidate_profile
  has_many :resume_analyses, class_name: "Recruitment::CandidateResumeAnalysis", dependent: :destroy,
           inverse_of: :candidate_profile
  has_one_attached :resume
  has_many_attached :portfolio_files

  accepts_nested_attributes_for :facts, allow_destroy: true,
                                reject_if: ->(attributes) { attributes["title"].blank? && attributes["detail"].blank? }
  attr_accessor :remove_resume, :remove_portfolio_files

  normalizes :headline, with: ->(value) { value.to_s.strip.presence }
  normalizes :summary, with: ->(value) { value.to_s.strip.presence }
  normalizes :preferred_location, with: ->(value) { value.to_s.strip.presence }
  normalizes :portfolio_url, :github_url, :linkedin_url, with: ->(value) { value.to_s.strip.presence }
  normalizes :salary_currency, with: ->(value) { value.to_s.strip.upcase }
  normalizes :visibility, with: ->(value) { value.to_s.strip.downcase }

  validates :user_id, uniqueness: true
  validates :headline, length: { maximum: 140 }
  validates :summary, length: { maximum: 2_000 }
  validates :preferred_location, length: { maximum: 160 }
  validates :portfolio_url, :github_url, :linkedin_url, length: { maximum: 500 }
  validates :salary_currency, format: { with: /\A[A-Z]{3}\z/ }
  validates :salary_expectation_min, :salary_expectation_max,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :visibility, inclusion: { in: VISIBILITIES }
  validate :user_must_be_a_student
  validate :urls_are_http
  validate :salary_range_is_ordered
  validate :attachments_are_safe
  before_save :stamp_consent

  def export_payload
    {
      "profile" => attributes.slice(
        "headline", "summary", "preferred_location", "portfolio_url", "github_url", "linkedin_url",
        "salary_expectation_min", "salary_expectation_max", "salary_currency", "visibility",
        "application_data_reuse_consent", "consent_given_at"
      ),
      "facts" => facts.ordered.map { |fact| fact.attributes.slice("kind", "title", "organization", "detail", "source", "confidence") },
      "resume_analyses" => resume_analyses.newest_first.includes(:findings).map do |analysis|
        {
          "provider" => analysis.provider, "status" => analysis.status, "source_label" => analysis.source_label,
          "uncertainty" => analysis.uncertainty, "generated_at" => analysis.generated_at,
          "findings" => analysis.findings.ordered.map do |finding|
            finding.attributes.slice("kind", "title", "detail", "evidence", "source_type", "confidence", "inferred", "status")
          end
        }
      end,
      "attachments" => { "resume" => resume.attached?, "portfolio_files" => portfolio_files.attachments.size }
    }
  end

  private
    def user_must_be_a_student
      errors.add(:user, :invalid) unless user&.student?
    end

    def urls_are_http
      URL_FIELDS.each do |field|
        value = public_send(field)
        next if value.blank?

        uri = URI.parse(value)
        errors.add(field, :invalid) unless uri.is_a?(URI::HTTP) && uri.host.present?
      rescue URI::InvalidURIError
        errors.add(field, :invalid)
      end
    end

    def salary_range_is_ordered
      return if salary_expectation_min.blank? || salary_expectation_max.blank? || salary_expectation_min <= salary_expectation_max

      errors.add(:salary_expectation_max, :greater_than_or_equal_to, count: salary_expectation_min)
    end

    def attachments_are_safe
      validate_attachments(resume, RESUME_CONTENT_TYPES, :resume) if resume.attached?
      portfolio_files.each { |attachment| validate_attachments(attachment, PORTFOLIO_CONTENT_TYPES, :portfolio_files) }
    end

    def validate_attachments(attachment, content_types, field)
      errors.add(field, :invalid) unless content_types.include?(attachment.content_type)
      errors.add(field, :too_large) if attachment.byte_size > MAX_ATTACHMENT_BYTES
    end

    def stamp_consent
      return unless will_save_change_to_application_data_reuse_consent?

      self.consent_given_at = application_data_reuse_consent? ? Time.current : nil
    end
end
