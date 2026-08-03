# One module of one course's syllabus: a number, a knowledge-unit count, and its
# topics in order. Named CourseModule rather than Module for the obvious reason.
#
# Status (done / now / locked) is NOT here and must not be: it is derived from
# what a learner has finished, so it belongs to the read model in Syllabus, not
# to the row.
class CourseModule < ApplicationRecord
  belongs_to :course
  has_many :topics, -> { order(:position) }, dependent: :destroy, inverse_of: :course_module

  validates :number, presence: true, uniqueness: { scope: :course_id }
  validates :units, numericality: { only_integer: true, greater_than: 0 }

  scope :in_order, -> { order(:number) }
end
