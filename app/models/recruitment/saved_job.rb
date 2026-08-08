module Recruitment
  class SavedJob < ApplicationRecord
    self.table_name = "recruitment_saved_jobs"

    belongs_to :user, inverse_of: :saved_jobs
    belongs_to :job_post, class_name: "Recruitment::JobPost", inverse_of: :saved_jobs

    validates :user_id, uniqueness: { scope: :job_post_id }
    validate :student_owner
    validate :job_is_discoverable, on: :create

    scope :newest_first, -> { order(created_at: :desc, id: :desc) }

    private
      def student_owner
        errors.add(:user, :invalid) unless user&.student?
      end

      def job_is_discoverable
        errors.add(:job_post, :invalid) unless Recruitment::JobPost.published_for_candidates.where(id: job_post_id).exists?
      end
  end
end
