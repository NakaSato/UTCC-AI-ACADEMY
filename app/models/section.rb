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
  # Nullable, but never a student: assigning one would put them on their own
  # Teaching console.
  validate :instructor_is_staff

  scope :taught_by, ->(user) { where(instructor: user) }

  private def instructor_is_staff
    errors.add(:instructor, :not_staff) if instructor && !instructor.staff?
  end

  # "AI1101 · BA-2" — how a section is named wherever both matter.
  def label = "#{course.code} · #{code}"

  # The term as the registrar writes it — "1/2569", Buddhist year — is what the
  # column stores, because that is what Thai staff will type. English readers
  # get the same term in the Gregorian year; the split is display, not storage,
  # so no date in the database carries a locale.
  BUDDHIST_OFFSET = 543
  # Above this a year can only be Buddhist — Gregorian stays below 2500 for
  # centuries — so a term someone already typed in Gregorian passes through.
  BUDDHIST_FLOOR = 2500

  def term_text
    return term unless I18n.locale == :en

    number, year = term.split("/")
    year.to_i >= BUDDHIST_FLOOR ? "#{number}/#{year.to_i - BUDDHIST_OFFSET}" : term
  end

  # The section a staff member's Teaching console is about. An instructor with
  # several teaches the one they were given first; there is no picker yet, and
  # inventing one before the screen has somewhere to put it would be guessing.
  def self.for_staff(user) = taught_by(user).order(:id).first || order(:id).first
end
