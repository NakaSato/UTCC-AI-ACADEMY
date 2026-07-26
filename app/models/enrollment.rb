# A student in a section. A join and nothing else — deliberately.
#
# Anything about how the student is *doing* belongs to topic_completions and
# submissions, which already record it. A grade or a progress column here would
# be a second copy of the same fact, free to disagree with the first.
class Enrollment < ApplicationRecord
  belongs_to :section
  belongs_to :user

  validates :user_id, uniqueness: { scope: :section_id }
end
