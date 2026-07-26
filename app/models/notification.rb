# One thing a user should hear about, written at the moment it happened. In-app
# only: the dropdown reads these, and nothing is delivered anywhere else.
#
# The row carries a kind and its interpolations, never a sentence — the copy is
# `notifications.<kind>` in the locale files, so the same row reads in Thai to
# one reader and English to another, and rewording a notification is a locale
# edit that retroactively rewords the history.
class Notification < ApplicationRecord
  belongs_to :user

  KINDS = %w[ enrolled role_changed integrity_notice integrity_escalated ].freeze

  validates :kind, inclusion: { in: KINDS }

  scope :unread, -> { where(read_at: nil) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  # The dropdown is a sidebar, not an archive.
  RECENT = 8

  def self.notify(user, kind, **params) = create!(user:, kind:, params:)

  def unread? = read_at.nil?

  def text = I18n.t("notifications.#{kind}", **interpolations)

  private
    # Stored values are keys where a key exists — a role is stored as "admin"
    # so the sentence can name it in the reader's language, not the granter's.
    def interpolations
      values = params.symbolize_keys
      values[:role] = I18n.t("admin.roles.#{values[:role]}") if values.key?(:role)
      values
    end
end
