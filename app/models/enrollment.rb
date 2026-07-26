# A student in a section. A join and nothing else — deliberately.
#
# Anything about how the student is *doing* belongs to topic_completions and
# submissions, which already record it. A grade or a progress column here would
# be a second copy of the same fact, free to disagree with the first.
class Enrollment < ApplicationRecord
  belongs_to :section
  belongs_to :user

  validates :user_id, uniqueness: { scope: :section_id }
  # A roster is students. Staff reach a section through sections.instructor_id,
  # and letting them in here too would put an instructor on the leaderboard of
  # the section they grade.
  validate :user_is_a_student

  private def user_is_a_student
    errors.add(:user, :not_student) if user && !user.student?
  end
end
