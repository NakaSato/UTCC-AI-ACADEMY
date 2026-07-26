class NotificationsController < ApplicationController
  # The bell's one write: everything unread becomes read. Back to wherever the
  # dropdown was open on.
  def read_all
    Current.user.notifications.unread.update_all(read_at: Time.current, updated_at: Time.current)

    redirect_back fallback_location: root_path
  end
end
