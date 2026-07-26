# A course in the catalog. Identity, taxonomy and numbers only — every word a
# human reads is still in config/locales, looked up by `code`, which is why
# CourseCatalog::Course can stay exactly the read model it was.
#
# This table is the other half of what TopicCompletion used to validate by hand:
# a completion can no longer name a course that does not exist, because the
# foreign key says so.
class Course < ApplicationRecord
  has_many :topic_completions, dependent: :destroy

  LEVELS = %w[ beginner intermediate advanced ].freeze

  validates :code, presence: true, uniqueness: true
  validates :position, presence: true, uniqueness: true
  validates :level, inclusion: { in: LEVELS }
  validates :credits, :projects, :hours, numericality: { only_integer: true, greater_than: 0 }

  scope :in_catalog_order, -> { order(:position) }

  # Stored as json, so it comes back as strings. The filters are symbols
  # everywhere else — CourseCatalog::FILTERS, the chip params, `tagged?` — so the
  # boundary is converted here rather than in eight call sites.
  def tags = self[:tags].map(&:to_sym)
end
