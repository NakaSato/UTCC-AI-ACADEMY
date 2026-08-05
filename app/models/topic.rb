# One topic in a course syllabus, and what a TopicCompletion now points at.
#
# `key` is "<module number>-<position>" — derived from the two, but stored and
# unique because it is the public identifier: /lesson?topic=2-3 carries it, and
# every "continue where you left off" link resolves through it.
class Topic < ApplicationRecord
  belongs_to :course_module, inverse_of: :topics
  has_one :course, through: :course_module
  has_many :topic_completions, dependent: :destroy
  has_many :prior_knowledges, dependent: :destroy

  # Which kinds count as "applied" rather than merely learned: the ones where
  # something gets built. The two My Learning bars are this split.
  APPLIED_KINDS = %w[ exercise code project mix ].freeze
  KINDS = (APPLIED_KINDS + %w[ theory ]).freeze

  validates :key, presence: true, uniqueness: true
  validates :kind, inclusion: { in: KINDS }
  validates :position, presence: true, uniqueness: { scope: :course_module_id }
  validates :minutes, numericality: { only_integer: true, greater_than: 0 }

  scope :in_syllabus_order, ->(course_code = "AI1101") {
    joins(:course_module).where(course_modules: { course_id: Course.find_by!(code: course_code).id })
                         .order("course_modules.number", :position)
  }

  def self.key_for(module_number, position, course_code: nil)
    prefix = course_code && course_code.to_s != "AI1101" ? "#{course_code}-" : ""
    "#{prefix}#{module_number}-#{position}"
  end

  def applied? = APPLIED_KINDS.include?(kind)
  def module_number = course_module.number
end
