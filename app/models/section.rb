# One course, one term, one instructor, and the students enrolled in it.
#
# This is what the leaderboard ranks within and what the Teaching console is a
# report on. Both used to name a section as a bare string — "BA-2" in a locale
# file — which is why neither could tell you who was in one.
class Section < ApplicationRecord
  belongs_to :course
  # Nullable: a section can be timetabled before anyone is assigned to teach it.
  belongs_to :instructor, class_name: "User", optional: true

  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments, source: :user

  validates :code, presence: true, uniqueness: { scope: %i[ course_id term ] }
  validates :term, presence: true

  scope :taught_by, ->(user) { where(instructor: user) }

  # "AI1101 · BA-2" — how a section is named wherever both matter.
  def label = "#{course.code} · #{code}"

  # The section a staff member's Teaching console is about. An instructor with
  # several teaches the one they were given first; there is no picker yet, and
  # inventing one before the screen has somewhere to put it would be guessing.
  def self.for_staff(user) = taught_by(user).order(:id).first || order(:id).first
end
