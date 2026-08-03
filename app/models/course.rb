# A course in the catalog. Identity, taxonomy and numbers only — every word a
# human reads is still in config/locales, looked up by `code`, which is why
# CourseCatalog::Course can stay exactly the read model it was.
#
# This table is the other half of what TopicCompletion used to validate by hand:
# a completion can no longer name a course that does not exist, because the
# foreign key says so.
class Course < ApplicationRecord
  has_many :topic_completions, dependent: :destroy
  has_many :course_modules, -> { order(:number) }, dependent: :restrict_with_exception
  has_many :topics, through: :course_modules
  has_many :sections, dependent: :restrict_with_exception
  has_many :enrollments, through: :sections

  LEVELS = %w[ beginner intermediate advanced ].freeze
  LIFECYCLE_STATES = %w[ draft published archived ].freeze
  TRANSITIONS = {
    draft: %w[ published ],
    published: %w[ archived ],
    archived: %w[ published ]
  }.freeze

  enum :lifecycle_state, LIFECYCLE_STATES.index_by(&:itself), validate: true

  validates :code, presence: true, uniqueness: true
  validates :position, presence: true, uniqueness: true
  validates :level, inclusion: { in: LEVELS }
  validates :credits, :projects, :hours, numericality: { only_integer: true, greater_than: 0 }

  scope :in_catalog_order, -> { order(:position) }
  scope :published_for_catalog, -> { where(lifecycle_state: :published) }

  def available_transitions = TRANSITIONS.fetch(lifecycle_state.to_sym, [])

  def transition_to!(target, expected_from: nil)
    target = target.to_s
    if expected_from.present? && expected_from.to_s != lifecycle_state
      errors.add(:lifecycle_state, :stale_transition)
      raise ActiveRecord::RecordInvalid, self
    end

    unless available_transitions.include?(target)
      errors.add(:lifecycle_state, :invalid_transition)
      raise ActiveRecord::RecordInvalid, self
    end

    update!(lifecycle_state: target)
  end

  # Stored as json, so it comes back as strings. The filters are symbols
  # everywhere else — CourseCatalog::FILTERS, the chip params, `tagged?` — so the
  # boundary is converted here rather than in eight call sites.
  def tags = self[:tags].map(&:to_sym)
end
