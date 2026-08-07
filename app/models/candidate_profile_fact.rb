class CandidateProfileFact < ApplicationRecord
  KINDS = %w[ education experience skill certification language ].freeze
  SOURCES = %w[ self_reported document_extracted human_reviewed ].freeze

  belongs_to :candidate_profile, inverse_of: :facts

  normalizes :kind, :source, with: ->(value) { value.to_s.strip.downcase }
  normalizes :title, :organization, :detail, with: ->(value) { value.to_s.strip }

  validates :kind, inclusion: { in: KINDS }
  validates :source, inclusion: { in: SOURCES }
  validates :title, presence: true, length: { maximum: 160 }
  validates :organization, length: { maximum: 160 }
  validates :detail, length: { maximum: 10_000 }
  validates :confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :profile_belongs_to_student

  scope :ordered, -> { order(position: :asc, id: :asc) }

  private
    def profile_belongs_to_student
      errors.add(:candidate_profile, :invalid) unless candidate_profile&.user&.student?
    end
end
