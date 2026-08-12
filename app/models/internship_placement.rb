# The internship itself, once a company has agreed to host a student.
#
# Deliberately separate from the decision that produced it: an approved request
# and a finished internship are different facts, and one status column covering
# both is the conflation SPEC-0041 exists to prevent.
#
# A placement carries exactly one origin, and it may be either an approved
# InternshipRequest or an accepted Recruitment::InternshipApplication — both are
# real internships. The origin is read-only in both directions: nothing here
# writes to an application, its status, or its evaluation, which SPEC-0028 owns.
class InternshipPlacement < ApplicationRecord
  STATUSES = %w[ planned active completed cancelled ].freeze
  OPEN_STATUSES = %w[ planned active ].freeze
  DECIDER_ROLES = InternshipRequest::DECIDER_ROLES
  TRANSITIONS = {
    "planned" => %w[ active cancelled ],
    "active" => %w[ completed cancelled ],
    "completed" => [],
    "cancelled" => []
  }.freeze

  belongs_to :organization, inverse_of: :internship_placements
  belongs_to :student, class_name: "User", inverse_of: :internship_placements
  belongs_to :internship_request, optional: true, inverse_of: :placement
  belongs_to :application, class_name: "Recruitment::InternshipApplication", optional: true
  has_many :progress_reports, class_name: "InternshipProgressReport", dependent: :restrict_with_exception,
                              inverse_of: :placement
  has_many :faculty_assignments, class_name: "InternshipFacultyAssignment",
                                 foreign_key: :internship_placement_id,
                                 dependent: :restrict_with_exception, inverse_of: :placement
  # Destroyed with the placement, unlike reports and assignments: a deliverable
  # is the student's file rather than evidence of what anyone decided, and they
  # may remove it themselves at any time anyway.
  has_many :deliverables, class_name: "InternshipDeliverable", foreign_key: :internship_placement_id,
                          dependent: :destroy, inverse_of: :placement

  def open? = OPEN_STATUSES.include?(status)

  attr_accessor :status_transition_context

  normalizes :status, with: ->(value) { value.to_s.strip.downcase }
  normalizes :cancellation_reason, with: ->(value) { value.to_s.strip.presence }

  validates :status, inclusion: { in: STATUSES }
  validates :cancellation_reason, length: { maximum: 5_000 }
  validate :exactly_one_origin
  validate :one_placement_per_origin, on: :create
  validate :origin_is_approved, on: :create
  validate :origin_matches_student_and_organization
  validate :initial_status_is_planned, on: :create
  validate :status_change_requires_transition_context, on: :update
  validate :settled_placement_is_immutable, on: :update
  validate :cancellation_states_a_reason
  validate :end_date_follows_start_date

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :open_placements, -> { where(status: OPEN_STATUSES) }

  def planned? = status == "planned"
  def active? = status == "active"
  def completed? = status == "completed"
  def cancelled? = status == "cancelled"
  def settled? = completed? || cancelled?

  def accepts_reports? = active?

  def origin = internship_request || application

  def self.from_request!(internship_request, actor:)
    raise ActiveRecord::RecordInvalid, internship_request unless internship_request.approved?

    create_for!(organization: internship_request.organization, student: internship_request.student,
                actor:, origin: { internship_request: })
  end

  def self.from_application!(application, actor:)
    raise ActiveRecord::RecordInvalid, application unless application.status == "accepted"

    create_for!(organization: application.program.organization, student: application.student,
                actor:, origin: { application: })
  end

  # Authorization is checked on the unsaved record, so an unauthorized attempt
  # never leaves a row behind.
  def self.create_for!(organization:, student:, actor:, origin:)
    placement = new(organization:, student:, **origin)
    raise ActiveRecord::RecordInvalid, placement unless placement.manageable_by?(actor)

    placement.save!
    placement
  end
  private_class_method :create_for!

  # Re-derived from the database rather than a loaded association, so a
  # membership revoked mid-session fails closed.
  def manageable_by?(user)
    return false unless user && Organization.active.where(id: organization_id).exists?

    OrganizationMembership.where(organization_id:, user_id: user.id, status: "active",
                                 role: DECIDER_ROLES).exists?
  end

  def visible_to?(user)
    return false if user.blank?

    student_id == user.id || manageable_by?(user) || supervised_by?(user)
  end

  # The assigned faculty supervisor, and only for this placement: the assignment
  # is the consent, so it is also the boundary. Re-derived from the database for
  # the same reason `manageable_by?` is — a revoked assignment must fail closed
  # mid-session. ADR-0041 decision 7, answered 2026-08-12.
  #
  # Deliberately not part of `manageable_by?`: reading is not deciding, and the
  # supervisor advances nothing.
  def supervised_by?(user)
    return false if user.blank?

    InternshipFacultyAssignment.active.exists?(internship_placement_id: id, faculty_id: user.id)
  end

  def supervisor = faculty_assignments.active.first&.faculty

  # The same rule as `InternshipDeliverable#readable_by?`, asked once for the
  # whole list instead of once per file. The company half of that rule is two
  # membership lookups, so filtering row by row cost two queries a deliverable
  # and grew with the pile — the one thing `test/models/query_budget_test.rb`
  # exists to stop.
  def deliverables_readable_by(user)
    return InternshipDeliverable.none if user.blank?

    readable = deliverables.newest_first.with_attached_file
    return readable if open? && manageable_by?(user)

    readable.where(author_id: user.id)
  end

  # An administrator assigns the supervisor, so they must be able to open the
  # placement — but ADR-0041 holds them to support scope and no unbounded
  # browsing of student content. So this is deliberately *not* `visible_to?`:
  # it opens the record, and the screen shows no word of a weekly report.
  def administrable_by?(user) = user.present? && user.admin?

  def activate!(actor:)
    transition!("active", actor:, stamps: { activated_at: Time.current })
  end

  def complete!(actor:)
    transition!("completed", actor:, stamps: { completed_at: Time.current })
  end

  def cancel!(actor:, reason:)
    transition!("cancelled", actor:, stamps: { cancelled_at: Time.current, cancellation_reason: reason })
  end

  # The Monday of the current week has no report yet, which is what a supervisor
  # wants to see. Computed, never stored: a missing report is an absence, not a
  # record.
  def missing_current_week_report?
    return false unless active?

    progress_reports.where(week_starting_on: Date.current.beginning_of_week).none?
  end

  private
    def transition!(target, actor:, stamps: {})
      updated = self.class.transaction do
        locked = self.class.lock.find(id)
        raise ActiveRecord::RecordInvalid, locked unless TRANSITIONS.fetch(locked.status, []).include?(target)
        raise ActiveRecord::RecordInvalid, locked unless locked.manageable_by?(actor)

        locked.status_transition_context = true
        locked.update!(status: target, **stamps)
        locked
      end
      assign_attributes(updated.attributes)
      self
    end

    def exactly_one_origin
      return if internship_request_id.present? ^ application_id.present?

      errors.add(:base, :invalid)
    end

    # The two partial unique indexes are the real guarantee; this makes the
    # ordinary "already placed" case a readable error rather than a violation.
    def one_placement_per_origin
      if internship_request_id.present? && self.class.where(internship_request_id:).where.not(id:).exists?
        errors.add(:internship_request, :taken)
      end
      return if application_id.blank?

      errors.add(:application, :taken) if self.class.where(application_id:).where.not(id:).exists?
    end

    def origin_is_approved
      if internship_request.present? && !internship_request.approved?
        errors.add(:internship_request, :invalid)
      end
      errors.add(:application, :invalid) if application.present? && application.status != "accepted"
    end

    def origin_matches_student_and_organization
      if internship_request.present? &&
         (internship_request.student_id != student_id || internship_request.organization_id != organization_id)
        errors.add(:internship_request, :invalid)
      end
      return if application.blank?

      if application.student_id != student_id || application.program.organization_id != organization_id
        errors.add(:application, :invalid)
      end
    end

    def initial_status_is_planned
      errors.add(:status, :invalid) unless planned?
    end

    def status_change_requires_transition_context
      return unless will_save_change_to_status?
      return if status_transition_context

      errors.add(:status, :invalid)
    end

    def settled_placement_is_immutable
      errors.add(:base, :invalid) if %w[ completed cancelled ].include?(status_was)
    end

    def cancellation_states_a_reason
      errors.add(:cancellation_reason, :blank) if cancelled? && cancellation_reason.blank?
    end

    def end_date_follows_start_date
      return if starts_on.blank? || ends_on.blank?

      errors.add(:ends_on, :invalid) if ends_on < starts_on
    end
end
