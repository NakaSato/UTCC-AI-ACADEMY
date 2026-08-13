# One thing an admin did, written at the moment it succeeded.
#
# The row carries an action and its interpolations, never a sentence — the copy
# is `audit.<action>` in the locale files, so the same row reads in Thai to one
# reader and English to another, and rewording an entry is a locale edit that
# retroactively rewords the history. That is `Notification`'s bargain, for the
# same reasons.
#
# There is no way to delete a row and nothing prunes them. An audit log you can
# clear is not one; at classroom scale nothing needs pruning, and if that ever
# changes it is a recurring job rather than a button on the screen.
class AuditEvent < ApplicationRecord
  belongs_to :user

  # Every mutating action on /admin. A reorder of the landing page's cards is
  # deliberately absent: it changes neither what exists nor who can do what, and
  # it is the noisiest control on the screen — a log full of reorders buries the
  # role grants.
  ACTIONS = %w[
    console_account_created console_password_reissued
    role_changed
    course_state_changed course_updated
    approval_decided
    proposal_decided
    feature_setting_changed
    lesson_integrity_setting_changed
    section_created section_updated enrolled unenrolled
    recruitment_organization_created recruitment_membership_granted recruitment_membership_revoked
    recruitment_invitation_created recruitment_invitation_accepted recruitment_invitation_declined
    recruitment_job_post_created recruitment_job_post_updated recruitment_job_post_deleted
    recruitment_job_post_submitted recruitment_job_post_changes_requested recruitment_job_post_published
    recruitment_job_post_paused recruitment_job_post_closed recruitment_job_post_archived
    recruitment_job_suggestions_generated recruitment_job_suggestion_edited
    recruitment_job_suggestion_accepted recruitment_job_suggestion_rejected
    recruitment_job_suggestion_regenerated
    recruitment_internship_program_created recruitment_internship_program_updated
    recruitment_internship_program_submitted recruitment_internship_program_changes_requested
    recruitment_internship_program_published recruitment_internship_program_paused
    recruitment_internship_program_closed recruitment_internship_program_archived
    recruitment_internship_application_created recruitment_internship_application_accepted
    recruitment_internship_application_rejected recruitment_internship_application_withdrawn
    recruitment_internship_evaluation_submitted
    recruitment_internship_suggestions_generated recruitment_internship_suggestion_edited
    recruitment_internship_suggestion_accepted recruitment_internship_suggestion_rejected
    recruitment_internship_suggestion_regenerated
    recruitment_resume_analysis_generated recruitment_resume_finding_edited
    recruitment_resume_finding_accepted recruitment_resume_finding_rejected
    recruitment_resume_analysis_applied
    recruitment_job_saved recruitment_job_unsaved recruitment_job_recommendation_dismissed
    recruitment_job_discovery_preferences_updated
    recruitment_job_application_created recruitment_job_application_withdrawn
    recruitment_job_application_transitioned recruitment_job_application_message_created
    integrity_closed integrity_notified integrity_escalated
    landing_saved card_added card_removed
    business_case_created business_case_updated business_case_published business_case_closed
    business_case_invitation_created business_case_invitation_accepted business_case_invitation_declined
    business_case_invitation_revoked
    business_case_mentor_assigned business_case_participant_revoked
    business_case_milestone_created business_case_milestone_completed
    business_case_submission_created business_case_comment_created
    internship_requests_opened internship_requests_closed
    internship_request_submitted internship_request_withdrawn
    internship_request_review_started internship_request_approved internship_request_rejected
    internship_placement_created internship_placement_activated internship_placement_completed
    internship_placement_cancelled
    internship_progress_report_submitted internship_progress_report_acknowledged
    internship_progress_report_faculty_acknowledged
    internship_faculty_assignment_created internship_faculty_assignment_revoked
    internship_request_resume_shared internship_request_resume_unshared
    internship_deliverable_added internship_deliverable_removed
  ].freeze

  # The ones worth noticing: a privilege change, or something that cannot be
  # undone from the screen that did it.
  WARN = %w[ console_account_created console_password_reissued role_changed course_state_changed approval_decided proposal_decided feature_setting_changed lesson_integrity_setting_changed
              unenrolled integrity_escalated card_removed recruitment_membership_revoked
              business_case_closed business_case_participant_revoked
              internship_requests_opened internship_request_rejected
              internship_placement_cancelled
              internship_faculty_assignment_created internship_faculty_assignment_revoked ].freeze

  validates :action, inclusion: { in: ACTIONS }

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  # In SQL rather than folded in Ruby, so that a page is taken from what is left
  # after the filter rather than from what was there before it. This used to cap
  # the tab at the most recent fifty rows, which is worse than no bound: the
  # older half of the log was unreachable and nothing on the screen said so. The
  # tab pages now, and every row is reachable — ADR-0050 decision 7.
  scope :at_level, ->(level) do
    case level&.to_sym
    in :warn then where(action: WARN)
    in :info then where.not(action: WARN)
    else all
    end
  end

  # The actor comes from Current.user rather than an argument, unlike
  # Notification.notify — a notification is about somebody other than whoever is
  # acting, and an audit entry never is. Nothing outside a request has an actor
  # to name, so a rake task or a seed that reaches this is a no-op rather than a
  # crash.
  def self.record(action, **params)
    create!(user: Current.user, action:, params:) if Current.user
  rescue ActiveRecord::ActiveRecordError => error
    Observability::Telemetry.emit("security.audit.failure", action:, error_class: error.class.name)
    raise
  end

  # Derived, not stored: which actions are worth a second look is a display
  # convention, and changing one should not need a backfill.
  def level = WARN.include?(action) ? :warn : :info

  def text = I18n.t("audit.#{action}", **interpolations)

  private
    # Stored values are keys where a key exists — a role is stored as "admin" and
    # a landing group as "tracks", so the sentence names them in the reader's
    # language rather than the actor's. A person's name and a card's title are
    # not keys and are stored as written.
    def interpolations
      values = params.symbolize_keys
      if values.key?(:role)
        key = values[:role]
        scope = I18n.exists?("admin.roles.#{key}") ? "admin.roles" : "recruitment.memberships.roles"
        values[:role] = I18n.t("#{scope}.#{key}")
      end
      values[:from] = I18n.t("admin.courses.state.#{values[:from]}") if values.key?(:from)
      values[:to] = I18n.t("admin.courses.state.#{values[:to]}") if values.key?(:to)
      values[:outcome] = I18n.t("admin.queue.status.#{values[:outcome]}") if values.key?(:outcome)
      values[:key] = I18n.t("admin.features.keys.#{values[:key]}") if values.key?(:key)
      values[:status] = I18n.t("proposal_request.status.#{values[:status]}") if values.key?(:status)
      %i[from_state to_state].each do |state|
        values[state] = I18n.t("admin.features.state.#{values[state]}") if values.key?(state)
      end
      %i[from_status to_status].each do |state|
        if values.key?(state) && I18n.exists?("recruitment.jobs.status.#{values[state]}")
          values[state] = I18n.t("recruitment.jobs.status.#{values[state]}")
        end
      end
      values[:access] = I18n.t("admin.console_account.access.#{values[:access]}") if values.key?(:access)
      values[:group] = I18n.t("admin.landing.sections.#{values[:group]}") if values.key?(:group)
      values
    end
end
