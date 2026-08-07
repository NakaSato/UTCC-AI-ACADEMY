module Recruitment
  class JobDiscoveryDismissal < ApplicationRecord
    self.table_name = "recruitment_job_discovery_dismissals"

    belongs_to :user, inverse_of: :job_discovery_dismissals
    belongs_to :job_post, class_name: "Recruitment::JobPost", inverse_of: :job_discovery_dismissals

    validates :user_id, uniqueness: { scope: :job_post_id }
    validate :student_owner

    private
      def student_owner
        errors.add(:user, :invalid) unless user&.student?
      end
  end
end
