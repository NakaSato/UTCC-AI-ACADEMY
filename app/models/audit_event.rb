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
    role_changed
    course_state_changed
    approval_decided
    feature_setting_changed
    lesson_integrity_setting_changed
    section_created section_updated enrolled unenrolled
    integrity_closed integrity_notified integrity_escalated
    landing_saved card_added card_removed
  ].freeze

  # The ones worth noticing: a privilege change, or something that cannot be
  # undone from the screen that did it.
  WARN = %w[ role_changed course_state_changed approval_decided feature_setting_changed lesson_integrity_setting_changed
              unenrolled integrity_escalated card_removed ].freeze

  # The tab is a sidebar, not an archive — the rows are all still there.
  RECENT = 50

  validates :action, inclusion: { in: ACTIONS }

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  # In SQL rather than folded in Ruby, so that RECENT caps what is left after
  # the filter rather than what was there before it.
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
      values[:role] = I18n.t("admin.roles.#{values[:role]}") if values.key?(:role)
      values[:from] = I18n.t("admin.courses.state.#{values[:from]}") if values.key?(:from)
      values[:to] = I18n.t("admin.courses.state.#{values[:to]}") if values.key?(:to)
      values[:outcome] = I18n.t("admin.queue.status.#{values[:outcome]}") if values.key?(:outcome)
      values[:key] = I18n.t("admin.features.keys.#{values[:key]}") if values.key?(:key)
      %i[from_state to_state].each do |state|
        values[state] = I18n.t("admin.features.state.#{values[state]}") if values.key?(state)
      end
      values[:group] = I18n.t("admin.landing.sections.#{values[:group]}") if values.key?(:group)
      values
    end
end
