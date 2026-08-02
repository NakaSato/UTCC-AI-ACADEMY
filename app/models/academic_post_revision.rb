class AcademicPostRevision < ApplicationRecord
  belongs_to :academic_post, inverse_of: :revisions
  belongs_to :author, class_name: "User", inverse_of: :academic_post_revisions

  validates :version, numericality: { only_integer: true, greater_than_or_equal_to: 0 },
                      uniqueness: { scope: :academic_post_id }
  validates :title, length: { maximum: 200 }
  validates :body, length: { maximum: 100_000 }
end
