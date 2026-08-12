class ProposalRequest < ApplicationRecord
  CATEGORIES = %w[ feature curriculum community platform ].freeze
  STATUSES = %w[ submitted in_review planned declined ].freeze

  # Every status the vocabulary allows, and what may follow it. `planned` and
  # `declined` are answers, so they are terminal: a decided proposal is not
  # re-decided, and an author is never told two contradictory things about the
  # same submission. Between them these cover all four — which is ADR-0049
  # decision 6 as the user settled it on 2026-08-12, and the reason no migration
  # of this table was needed. SPEC-0050.
  TRANSITIONS = {
    "submitted" => %w[ in_review planned declined ],
    "in_review" => %w[ planned declined ],
    "planned" => [].freeze,
    "declined" => [].freeze
  }.freeze

  # What an administrator still has something to do about.
  UNDECIDED = %w[ submitted in_review ].freeze

  belongs_to :user, inverse_of: :proposal_requests
  has_many :decisions, class_name: "ProposalDecision", dependent: :destroy, inverse_of: :proposal_request

  normalizes :title, :category, :problem, :idea, :impact, with: ->(value) { value.to_s.strip.presence }

  validates :title, presence: true, length: { maximum: 160 }
  validates :category, inclusion: { in: CATEGORIES }
  validates :problem, presence: true, length: { maximum: 2_000 }
  validates :idea, presence: true, length: { maximum: 4_000 }
  validates :impact, presence: true, length: { maximum: 1_000 }
  validates :status, inclusion: { in: STATUSES }
  validate :user_must_be_a_contributor

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :undecided, -> { where(status: UNDECIDED) }

  def reference = "PR-%04d" % id

  def decided? = TRANSITIONS.fetch(status).empty?
  def decidable_by?(actor) = actor&.admin? && !decided?

  # The status and the record explaining it are written together or not at all,
  # under a lock, so two administrators deciding at once produce one decision
  # and one refusal rather than two decisions on top of each other.
  def decide!(actor:, to_status:, reason:)
    to_status = to_status.to_s

    with_lock do
      raise ActiveRecord::RecordInvalid, self unless decidable_by?(actor)
      raise ActiveRecord::RecordInvalid, self unless TRANSITIONS.fetch(status).include?(to_status)

      decisions.create!(actor:, to_status:, reason:)
      update!(status: to_status)
    end
  end

  # What the author is told. The last decision is the current answer; the ones
  # before it are history nobody outside the console reads.
  def latest_decision = decisions.newest_first.first

  private
    def user_must_be_a_contributor
      errors.add(:user, :invalid) unless user&.student? || user&.instructor?
    end
end
