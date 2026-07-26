# One module of the syllabus: a number, a knowledge-unit count, and its topics in
# order. Named CourseModule rather than Module for the obvious reason.
#
# It belongs to no course. Every course reuses this one syllabus, exactly as
# Syllabus::ENTRIES did — `course_id` is the column to add on the day someone has
# written a second syllabus to put in it.
#
# Status (done / now / locked) is NOT here and must not be: it is derived from
# what a learner has finished, so it belongs to the read model in Syllabus, not
# to the row.
class CourseModule < ApplicationRecord
  has_many :topics, -> { order(:position) }, dependent: :destroy, inverse_of: :course_module

  validates :number, presence: true, uniqueness: true
  validates :units, numericality: { only_integer: true, greater_than: 0 }

  scope :in_order, -> { order(:number) }
end
