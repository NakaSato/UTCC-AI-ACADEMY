module Recruitment
  class InternshipApplication < ApplicationRecord
    self.table_name = "recruitment_internship_applications"

    STATUSES = %w[ pending accepted rejected withdrawn ].freeze

    belongs_to :program, class_name: "Recruitment::InternshipProgram", inverse_of: :applications
    belongs_to :student, class_name: "User", inverse_of: :internship_applications
    belongs_to :reviewed_by, class_name: "User", optional: true, inverse_of: :reviewed_internship_applications
    has_one :evaluation, class_name: "Recruitment::InternshipEvaluation", dependent: :restrict_with_exception,
                         inverse_of: :application

    normalizes :status, with: ->(value) { value.to_s.strip.downcase }
    normalizes :statement, with: ->(value) { value.to_s.strip }

    validates :status, inclusion: { in: STATUSES }
    validates :statement, length: { maximum: 10_000 }
    validates :applied_at, presence: true
    validates :student_id, uniqueness: { scope: :program_id }
    validate :student_account
    validate :reviewer_can_manage

    scope :newest_first, -> { order(created_at: :desc, id: :desc) }
    scope :accepted, -> { where(status: "accepted") }

    before_validation :set_application_time, on: :create

    def pending? = status == "pending"
    def accepted? = status == "accepted"
    def rejected? = status == "rejected"
    def withdrawn? = status == "withdrawn"

    def accept!(reviewer:)
      raise ActiveRecord::RecordInvalid, self unless pending?

      program.with_lock do
        raise ActiveRecord::RecordInvalid, self unless program.published? &&
                                                        program.applications.where(status: "accepted").count < program.max_students

        update!(status: "accepted", reviewed_by: reviewer, reviewed_at: Time.current)
      end
    end

    def reject!(reviewer:)
      raise ActiveRecord::RecordInvalid, self unless pending?

      update!(status: "rejected", reviewed_by: reviewer, reviewed_at: Time.current)
    end

    def withdraw!
      raise ActiveRecord::RecordInvalid, self unless pending? || accepted?

      update!(status: "withdrawn")
    end

    private
      def set_application_time
        self.applied_at ||= Time.current
      end

      def student_account
        errors.add(:student, :invalid) unless student&.student?
      end

      def reviewer_can_manage
        return if reviewed_by.blank? || program.blank?
        return if reviewed_by.admin?
        return if program.organization.memberships.active.exists?(user_id: reviewed_by_id,
                                                                    role: Recruitment::InternshipProgram::REVIEWER_ROLES)

        errors.add(:reviewed_by, :invalid)
      end
  end
end
