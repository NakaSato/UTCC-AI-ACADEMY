# One recorded answer to a proposal: who decided it, when, the status it moved
# to, and the reason the author reads. ADR-0049 decision 5 — a decision is a
# record, not a column, because a status overwritten in place cannot answer "who
# decided this and why", which is the whole of "auditable" in M13's outcome.
#
# Shaped after ApprovalDecision, which does the same job for the course
# lifecycle. It is a separate record rather than a reuse: `approval_requests`
# requires a course, and its outcomes are approved/rejected, which a triage
# outcome is not — see ADR-0049's answer of 2026-08-12.
class ProposalDecision < ApplicationRecord
  # `submitted` is absent on purpose. It is what the intake writes; a proposal
  # is never decided *into* the queue it came from, because "undecided again"
  # is not something an author can be told.
  OUTCOMES = %w[ in_review planned declined ].freeze

  belongs_to :proposal_request, inverse_of: :decisions
  belongs_to :actor, class_name: "User"

  normalizes :reason, with: ->(value) { value.to_s.strip.presence }

  validates :to_status, inclusion: { in: OUTCOMES }
  validates :reason, presence: true, length: { maximum: 1_000 }
  validate :actor_is_an_administrator

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :oldest_first, -> { order(created_at: :asc, id: :asc) }

  # The author was told this. Nothing may edit it afterwards and nothing may
  # make it disappear, which is the same rule ApprovalDecision runs on.
  before_update { throw :abort }
  before_destroy { throw :abort }

  private
    def actor_is_an_administrator
      errors.add(:actor, :invalid) unless actor&.admin?
    end
end
