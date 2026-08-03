class ApprovalRequest < ApplicationRecord
  COURSE_LIFECYCLE_TRANSITION = "course_lifecycle_transition".freeze
  KINDS = [ COURSE_LIFECYCLE_TRANSITION ].freeze
  STATUSES = %w[ pending approved rejected ].freeze
  APPROVER_ROLES = %w[ admin ].freeze

  belongs_to :course
  belongs_to :requester, class_name: "User"
  has_many :decisions, class_name: "ApprovalDecision", dependent: :restrict_with_exception,
                       inverse_of: :approval_request

  enum :status, STATUSES.index_by(&:itself), default: "pending", validate: true

  validates :kind, inclusion: { in: KINDS }
  validates :from_state, :to_state, presence: true
  validates :note, length: { maximum: 500 }, allow_blank: true
  validate :requester_is_approver
  validate :course_transition_is_allowed, on: :create
  validate :pending_request_is_unique, on: :create

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :oldest_first, -> { order(created_at: :asc, id: :asc) }

  def self.create_course_lifecycle!(course:, requester:, to_state:, from_state: nil, note: nil)
    new(course:, requester:, kind: COURSE_LIFECYCLE_TRANSITION,
        from_state: from_state.presence || course.lifecycle_state, to_state:, note:)
      .tap(&:save!)
  end

  def course_lifecycle_transition? = kind == COURSE_LIFECYCLE_TRANSITION

  def approvable_by?(actor)
    pending? && approver?(actor) && requester_id != actor.id
  end

  def decide!(actor:, outcome:, note: nil)
    outcome = outcome.to_s
    raise ActiveRecord::RecordInvalid, self unless %w[ approved rejected ].include?(outcome)
    raise ActiveRecord::RecordInvalid, self unless approvable_by?(actor)

    transaction do
      lock!
      raise ActiveRecord::RecordInvalid, self unless approvable_by?(actor)
      raise ActiveRecord::RecordInvalid, self unless course.reload.lifecycle_state == from_state

      course.transition_to!(to_state, expected_from: from_state) if outcome == "approved"
      ApprovalDecision.create!(approval_request: self, actor:, outcome:, note:)
      update!(status: outcome, decided_at: Time.current)
      AuditEvent.record("approval_decided", request_id: id, course: course.code, outcome:,
                        from: from_state, to: course.lifecycle_state, reason: note.presence)
    end

    self
  end

  def title = I18n.t("admin.queue.course_transition_title", course: course.code)

  def requester_role = I18n.t("admin.roles.#{requester.role}")

  private
    def approver?(actor) = actor.present? && APPROVER_ROLES.include?(actor.role)

    def requester_is_approver
      errors.add(:requester, :invalid) unless approver?(requester)
    end

    def course_transition_is_allowed
      return unless course_lifecycle_transition? && course && from_state.present? && to_state.present?

      errors.add(:to_state, :invalid) unless course.lifecycle_state == from_state &&
        course.available_transitions.include?(to_state)
    end

    def pending_request_is_unique
      return unless course_id && from_state && to_state

      duplicate = self.class.pending.where(course_id:, from_state:, to_state:).exists?
      errors.add(:course, :taken) if duplicate
    end
end
