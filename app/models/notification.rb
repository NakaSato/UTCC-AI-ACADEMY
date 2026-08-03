# One thing a user should hear about, written at the moment it happened. In-app
# only: the dropdown reads these, and nothing is delivered anywhere else.
#
# The row carries a kind and its interpolations, never a sentence — the copy is
# `notifications.<kind>` in the locale files, so the same row reads in Thai to
# one reader and English to another, and rewording a notification is a locale
# edit that retroactively rewords the history.
class Notification < ApplicationRecord
  after_create_commit :broadcast_refresh

  belongs_to :user

  KINDS = %w[ enrolled role_changed integrity_notice integrity_escalated academic_post_invitation ].freeze

  validates :kind, inclusion: { in: KINDS }

  scope :unread, -> { where(read_at: nil) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  # The dropdown is a sidebar, not an archive.
  RECENT = 8

  # The one place a notification is written, and therefore the one place the
  # bell has to be told. Every caller is in AdminController acting *on* somebody
  # else, so the recipient is by definition looking at a different page than the
  # one that caused this — see NotificationBell.
  def self.notify(user, kind, **params)
    return unless FeatureSetting.enabled?(:notifications)

    create!(user:, kind:, params:)
  end

  def unread? = read_at.nil?

  def text = I18n.t("notifications.#{kind}", **interpolations)

  def action_path
    return unless kind == "academic_post_invitation"

    Rails.application.routes.url_helpers.academic_post_invitation_path(params.fetch("token"))
  end

  def action_label
    return unless kind == "academic_post_invitation"

    I18n.t("notifications.academic_post_invitation_action")
  end

  private
    def broadcast_refresh = NotificationBell.new(user).broadcast_refresh!

    # Stored values are keys where a key exists — a role is stored as "admin"
    # so the sentence can name it in the reader's language, not the granter's.
    def interpolations
      values = params.symbolize_keys
      values[:role] = I18n.t("admin.roles.#{values[:role]}") if values.key?(:role)
      values
    end
end
