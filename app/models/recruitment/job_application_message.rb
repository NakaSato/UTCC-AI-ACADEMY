module Recruitment
  class JobApplicationMessage < ApplicationRecord
    self.table_name = "recruitment_job_application_messages"

    belongs_to :job_application, class_name: "Recruitment::JobApplication", inverse_of: :messages
    belongs_to :sender, class_name: "User", inverse_of: :sent_job_application_messages

    normalizes :body, with: ->(value) { value.to_s.strip }

    validates :body, presence: true, length: { maximum: 4_000 }
    validates :sent_at, presence: true
    validate :sender_can_participate

    before_validation :set_sent_time, on: :create
    before_update { throw :abort }
    before_destroy { throw :abort }
    after_create :record_audit_event

    private
      def set_sent_time
        self.sent_at ||= Time.current
      end

      def sender_can_participate
        return if sender.blank? || job_application.blank?
        return if Recruitment::JobApplication.where(id: job_application.id, candidate_id: sender.id).exists? ||
                  job_application.reviewer?(sender)

        errors.add(:sender, :invalid)
      end

      def record_audit_event
        AuditEvent.create!(user: sender, action: "recruitment_job_application_message_created",
                           params: { organization: job_application.job_post.organization.name,
                                     job: job_application.job_post.title, application: job_application.id })
      end
  end
end
