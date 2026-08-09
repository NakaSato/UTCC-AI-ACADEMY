module Recruitment
  class JobPost < ApplicationRecord
    self.table_name = "recruitment_job_posts"

    STATUSES = %w[ draft review published paused closed archived ].freeze
    EMPLOYMENT_TYPES = %w[ full_time part_time internship contract freelance ].freeze
    REMOTE_POLICIES = %w[ onsite hybrid remote ].freeze
    AUTHOR_ROLES = %w[ owner recruiter hiring_manager company_reviewer ].freeze
    # Publication approval stays with the two accountable roles; a company
    # reviewer drafts and reviews but does not approve its own posting.
    APPROVER_ROLES = %w[ owner hiring_manager ].freeze
    TRANSITIONS = {
      "draft" => %w[ review archived ],
      "review" => %w[ draft published archived ],
      "published" => %w[ paused closed ],
      "paused" => %w[ published closed archived ],
      "closed" => %w[ archived ],
      "archived" => []
    }.freeze

    belongs_to :organization, inverse_of: :job_posts
    belongs_to :creator, class_name: "User", inverse_of: :created_recruitment_job_posts
    has_many :suggestions, class_name: "Recruitment::JobPostSuggestion", dependent: :restrict_with_exception,
                           inverse_of: :job_post
    has_many :saved_jobs, class_name: "Recruitment::SavedJob", dependent: :destroy, inverse_of: :job_post, validate: false
    has_many :job_discovery_dismissals, class_name: "Recruitment::JobDiscoveryDismissal", dependent: :destroy,
                                        inverse_of: :job_post
    has_many :applications, class_name: "Recruitment::JobApplication", dependent: :restrict_with_exception,
                            inverse_of: :job_post, validate: false

    normalizes :title, :summary, :description, :category, :department, :team, :seniority, :location, :hiring_reason,
               with: ->(value) { value.to_s.strip }
    normalizes :employment_type, :remote_policy, :status, with: ->(value) { value.to_s.strip.downcase }
    normalizes :currency, with: ->(value) { value.to_s.strip.upcase }

    validates :title, length: { maximum: 200 }
    validates :summary, length: { maximum: 2_000 }
    validates :description, length: { maximum: 20_000 }
    validates :category, :department, :team, :seniority, :location, length: { maximum: 160 }
    validates :currency, format: { with: /\A[A-Z]{3}\z/ }
    validates :status, inclusion: { in: STATUSES }
    validates :employment_type, inclusion: { in: EMPLOYMENT_TYPES }
    validates :remote_policy, inclusion: { in: REMOTE_POLICIES }
    validates :salary_min, :salary_max, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
    validates :hiring_reason, length: { maximum: 2_000 }
    validates :positions_count, numericality: { only_integer: true, greater_than: 0 }
    validate :salary_range_is_ordered
    validate :creator_can_manage
    before_destroy :ensure_draft_for_destroy

    scope :published_for_candidates, -> do
      joins(:organization)
        .where(status: "published", organizations: { status: "active" })
        .where("recruitment_job_posts.closes_on IS NULL OR recruitment_job_posts.closes_on >= ?", Date.current)
    end

    def draft? = status == "draft"
    def review? = status == "review"
    def published? = status == "published"
    def paused? = status == "paused"
    def closed? = status == "closed"
    def archived? = status == "archived"

    def ready_for_publication?
      %i[ title summary description category department seniority employment_type location remote_policy ].all? do |field|
        public_send(field).present?
      end
    end

    def visible_to_candidates?
      published? && organization.active? && (closes_on.blank? || closes_on >= Date.current)
    end

    def editable?
      draft? || paused?
    end

    def transition_to!(target)
      target = target.to_s
      raise ActiveRecord::RecordInvalid, self unless TRANSITIONS.fetch(status, []).include?(target)
      raise ActiveRecord::RecordInvalid, self if %w[ review published ].include?(target) && !ready_for_publication?

      self.status = target
      self.published_at ||= Time.current if target == "published"
      self.closed_at = Time.current if target == "closed"
      self.archived_at = Time.current if target == "archived"
      save!
    end

    private
      def salary_range_is_ordered
        return if salary_min.blank? || salary_max.blank? || salary_min <= salary_max

        errors.add(:salary_max, :greater_than_or_equal_to, count: salary_min)
      end

      def creator_can_manage
        return if creator.blank? || organization.blank?
        return if creator.admin?
        return if organization.memberships.active.exists?(user_id: creator_id, role: AUTHOR_ROLES)

        errors.add(:creator, :invalid)
      end

      def ensure_draft_for_destroy
        throw(:abort) unless draft?
      end
  end
end
