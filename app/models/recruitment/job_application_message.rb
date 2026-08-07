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

    private
      def set_sent_time
        self.sent_at ||= Time.current
      end

      def sender_can_participate
        return if sender.blank? || job_application.blank?
        return if sender.id == job_application.candidate_id || job_application.reviewer?(sender)

        errors.add(:sender, :invalid)
      end
  end
end
