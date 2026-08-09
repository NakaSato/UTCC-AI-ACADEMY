class BusinessCaseMilestone < ApplicationRecord
  STATUSES = %w[ open completed ].freeze

  belongs_to :business_case, inverse_of: :milestones
  has_many :submissions, class_name: "BusinessCaseSubmission", foreign_key: :business_case_milestone_id,
                         dependent: :restrict_with_exception, inverse_of: :milestone

  normalizes :title, with: ->(value) { value.to_s.strip }

  validates :title, presence: true, length: { maximum: 160 }
  validates :description, length: { maximum: 10_000 }
  validates :status, inclusion: { in: STATUSES }
  validates :position, presence: true, numericality: { greater_than: 0, only_integer: true },
                       uniqueness: { scope: :business_case_id }
  validate :business_case_is_not_closed

  before_validation :assign_position, on: :create

  scope :ordered, -> { order(:position) }

  def open? = status == "open"
  def completed? = status == "completed"

  def complete!
    with_lock do
      raise ActiveRecord::RecordInvalid, self unless open? && !business_case.closed?

      update!(status: "completed", completed_at: Time.current)
    end
  end

  private
    def assign_position
      return if position.present? || business_case.blank?

      self.position = (business_case.milestones.maximum(:position) || 0) + 1
    end

    def business_case_is_not_closed
      errors.add(:business_case, :invalid) if business_case&.closed?
    end
end
