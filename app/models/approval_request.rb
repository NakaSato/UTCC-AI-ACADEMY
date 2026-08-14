class ApprovalRequest < ApplicationRecord
  COURSE_LIFECYCLE_TRANSITION = "course_lifecycle_transition".freeze
  # A teacher may rename and reorder their own lessons (SPEC-0054); adding one
  # changes what exists, so it is asked for here and an administrator decides it.
  # Removing one is deliberately not a kind — see `SyllabusBuilder`, and the spec:
  # a topic has completions and submissions pointing at it, and taking it away is
  # a retirement rather than a delete.
  SYLLABUS_LESSON_ADDED = "syllabus_lesson_added".freeze
  KINDS = [ COURSE_LIFECYCLE_TRANSITION, SYLLABUS_LESSON_ADDED ].freeze
  STATUSES = %w[ pending approved rejected ].freeze
  APPROVER_ROLES = %w[ admin ].freeze

  belongs_to :course
  belongs_to :requester, class_name: "User"
  has_many :decisions, class_name: "ApprovalDecision", dependent: :restrict_with_exception,
                       inverse_of: :approval_request

  enum :status, STATUSES.index_by(&:itself), default: "pending", validate: true

  validates :kind, inclusion: { in: KINDS }
  # The two state columns are the lifecycle request's whole payload, and are
  # required for exactly that kind. A lesson request has no state to move
  # between; what it carries is in `payload`.
  validates :from_state, :to_state, presence: true, if: :course_lifecycle_transition?
  validates :note, length: { maximum: 500 }, allow_blank: true
  validate :requester_is_approver
  validate :course_transition_is_allowed, on: :create
  validate :pending_request_is_unique, on: :create
  validate :lesson_payload_is_complete, on: :create, if: :syllabus_lesson_added?

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :oldest_first, -> { order(created_at: :asc, id: :asc) }

  def self.create_course_lifecycle!(course:, requester:, to_state:, from_state: nil, note: nil)
    new(course:, requester:, kind: COURSE_LIFECYCLE_TRANSITION,
        from_state: from_state.presence || course.lifecycle_state, to_state:, note:)
      .tap(&:save!)
  end

  # Everything the lesson has to arrive with, because approving it is what
  # creates the row — there is nowhere else for a name or a duration to come from
  # at decision time.
  def self.create_lesson_addition!(course:, requester:, module_number:, topic_kind:, minutes:, names:, note: nil)
    new(course:, requester:, kind: SYLLABUS_LESSON_ADDED, note:,
        payload: { "module_number" => module_number.to_i, "topic_kind" => topic_kind.to_s,
                   "minutes" => minutes.to_i, "names" => names.transform_keys(&:to_s) })
      .tap(&:save!)
  end

  def course_lifecycle_transition? = kind == COURSE_LIFECYCLE_TRANSITION
  def syllabus_lesson_added? = kind == SYLLABUS_LESSON_ADDED

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
      # A lifecycle request is only still answerable from the state it was raised
      # against. A lesson request is not about the course's state at all, so it
      # does not go stale when the course moves.
      if course_lifecycle_transition?
        raise ActiveRecord::RecordInvalid, self unless course.reload.lifecycle_state == from_state
      end

      apply! if outcome == "approved"
      ApprovalDecision.create!(approval_request: self, actor:, outcome:, note:)
      update!(status: outcome, decided_at: Time.current)
      record_decision(outcome, note)
    end

    self
  end

  def title
    return I18n.t("admin.queue.course_transition_title", course: course.code) if course_lifecycle_transition?

    I18n.t("admin.queue.lesson_addition_title", course: course.code,
           module_number: payload["module_number"], lesson: lesson_name)
  end

  # What the request is asking to call the lesson, in the reader's language,
  # falling back to whichever language it was written in.
  def lesson_name
    names = payload["names"].to_h
    names[I18n.locale.to_s].presence || names.values.compact_blank.first.to_s
  end

  # The line under the title. A lifecycle request reads as a move between two
  # states; a lesson request has no states to name, so it names what it would add.
  def meta_text
    if course_lifecycle_transition?
      I18n.t("admin.queue.request_meta", role: requester_role,
             from: I18n.t("admin.courses.state.#{from_state}"),
             to: I18n.t("admin.courses.state.#{to_state}"))
    else
      I18n.t("admin.queue.lesson_meta", role: requester_role,
             kind: I18n.t("course.kind.#{payload["topic_kind"]}"),
             minutes: I18n.t("units.minutes", count: payload["minutes"].to_i))
    end
  end

  def requester_role = I18n.t("admin.roles.#{requester.role}")

  private
    # A decision on a lesson is not a decision on a lifecycle, and one sentence
    # cannot honestly say both: `audit.approval_decided` reads "the %{course}
    # *lifecycle* request from %{from} to %{to}", and a lesson request has no
    # states to put in those slots. Worse than reading oddly — `interpolations`
    # resolves `from` through `admin.courses.state.<value>`, so a nil state
    # interpolated the whole state subtree into the sentence as a hash.
    def record_decision(outcome, note)
      if course_lifecycle_transition?
        AuditEvent.record("approval_decided", request_id: id, course: course.code, outcome:,
                          from: from_state, to: course.lifecycle_state, reason: note.presence)
      else
        AuditEvent.record("lesson_addition_decided", request_id: id, course: course.code, outcome:,
                          lesson: lesson_name, reason: note.presence)
      end
    end

    # What approving actually does, per kind. Inside `decide!`'s transaction and
    # its lock, so a request cannot be applied twice.
    def apply!
      if course_lifecycle_transition?
        course.transition_to!(to_state, expected_from: from_state)
      else
        SyllabusBuilder.new(course).add_lesson!(
          module_number: payload["module_number"], topic_kind: payload["topic_kind"],
          minutes: payload["minutes"], names: payload["names"].to_h
        )
      end
    end

    # A request that would create an unnamed, zero-minute lesson in a module that
    # does not exist is not a request an administrator should be shown at all.
    def lesson_payload_is_complete
      errors.add(:payload, :invalid) unless course&.course_modules&.exists?(number: payload["module_number"])
      errors.add(:payload, :invalid) unless Topic::KINDS.include?(payload["topic_kind"].to_s)
      errors.add(:payload, :invalid) unless payload["minutes"].to_i.positive?

      names = payload["names"].to_h
      missing = I18n.available_locales.map(&:to_s).reject { names[it].to_s.strip.present? }
      errors.add(:payload, :blank) if missing.any?
    end

    def approver?(actor) = actor.present? && APPROVER_ROLES.include?(actor.role)

    # Who may raise a request: an approver, or the teacher of the course it is
    # about (ADR-0054 decision 3). The queue widened by exactly this one rule and
    # nothing else — `approvable_by?` above is untouched, so a teacher cannot
    # decide their own request and neither can the administrator who raised one.
    # That refusal is the whole reason the queue exists (ADR-0013).
    def requester_is_approver
      return if approver?(requester)
      return if course && requester && course.taught_by?(requester)

      errors.add(:requester, :invalid)
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
