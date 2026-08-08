module Recruitment
  class JobApplicationEvent < ApplicationRecord
    self.table_name = "recruitment_job_application_events"

    belongs_to :job_application, class_name: "Recruitment::JobApplication", inverse_of: :events
    belongs_to :actor, class_name: "User", inverse_of: :job_application_events

    normalizes :from_status, :to_status, with: ->(value) { value.to_s.strip.downcase }
    normalizes :note, with: ->(value) { value.to_s.strip }

    validates :to_status, inclusion: { in: Recruitment::JobApplication::STATUSES }
    validates :from_status, inclusion: { in: Recruitment::JobApplication::STATUSES }, allow_nil: true
    validates :note, length: { maximum: 2_000 }
    validates :occurred_at, presence: true

    before_update { throw :abort }
    before_destroy { throw :abort }
  end
end
