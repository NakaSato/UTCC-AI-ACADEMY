module Recruitment
  class InternshipProgram < ApplicationRecord
    self.table_name = "recruitment_internship_programs"

    STATUSES = %w[ draft review published paused closed archived ].freeze
    REMOTE_POLICIES = %w[ onsite hybrid remote ].freeze
    AUTHOR_ROLES = %w[ owner recruiter hiring_manager ].freeze
    REVIEWER_ROLES = %w[ owner recruiter hiring_manager mentor ].freeze
    TRANSITIONS = {
      "draft" => %w[ review archived ],
      "review" => %w[ draft published archived ],
      "published" => %w[ paused closed ],
      "paused" => %w[ published closed archived ],
      "closed" => %w[ archived ],
      "archived" => []
    }.freeze

    belongs_to :organization, inverse_of: :internship_programs
    belongs_to :creator, class_name: "User", inverse_of: :created_internship_programs
    belongs_to :mentor, class_name: "User", optional: true, inverse_of: :mentored_internship_programs
    has_many :applications, class_name: "Recruitment::InternshipApplication", dependent: :restrict_with_exception,
                           inverse_of: :program
    has_many :suggestions, class_name: "Recruitment::InternshipProgramSuggestion", dependent: :restrict_with_exception,
                           inverse_of: :program

    normalizes :name, :department, :description, :required_skills, :learning_outcomes, :working_days,
               :certificate_policy, :equipment_provided, with: ->(value) { value.to_s.strip }
    normalizes :remote_policy, :status, with: ->(value) { value.to_s.strip.downcase }

    validates :name, length: { maximum: 200 }
    validates :department, length: { maximum: 160 }
    validates :description, length: { maximum: 20_000 }
    validates :required_skills, :learning_outcomes, :working_days, :certificate_policy, :equipment_provided,
              length: { maximum: 10_000 }
    validates :duration_weeks, numericality: { only_integer: true, in: 1..104 }
    validates :max_students, numericality: { only_integer: true, greater_than: 0 }
    validates :remote_policy, inclusion: { in: REMOTE_POLICIES }
    validates :status, inclusion: { in: STATUSES }
    validate :creator_can_manage
    validate :mentor_can_manage

    scope :published_for_candidates, -> do
      joins(:organization)
        .where(status: "published", organizations: { status: "active" })
    end

    def draft? = status == "draft"
    def review? = status == "review"
    def published? = status == "published"
    def paused? = status == "paused"
    def closed? = status == "closed"
    def archived? = status == "archived"
    def editable? = draft? || paused?

    def ready_for_publication?
      %i[ name department description required_skills learning_outcomes working_days certificate_policy mentor ].all? do |field|
        public_send(field).present?
      end
    end

    def accepting_applications?
      published? && applications.where(status: %w[ pending accepted ]).count < max_students
    end

    def apply!(student:, statement:)
      with_lock do
        raise ActiveRecord::RecordInvalid, self unless published? &&
                                                        applications.where(status: %w[ pending accepted ]).count < max_students

        applications.create!(student:, statement:)
      end
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
      def creator_can_manage
        return if creator.blank? || organization.blank?
        return if creator.admin?
        return if organization.memberships.active.exists?(user_id: creator_id, role: AUTHOR_ROLES)

        errors.add(:creator, :invalid)
      end

      def mentor_can_manage
        return if mentor.blank? || organization.blank?
        return if mentor.admin?
        return if organization.memberships.active.exists?(user_id: mentor_id, role: %w[ owner hiring_manager mentor ])

        errors.add(:mentor, :invalid)
      end
  end
end
