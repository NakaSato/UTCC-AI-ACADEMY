class NotificationsController < ApplicationController
  # The bell, alone. This is what the frame a broadcast pushes comes back for, and
  # the whole reason the broadcast pushes a frame instead of the bell itself: an
  # ordinary request has the reader's session, so the copy is in their language
  # and the panel's form carries a token they can actually submit.
  #
  # It renders the same partial the header does, so the pushed bell and the loaded
  # one cannot drift apart. turbo-rails swaps in its own minimal layout for a
  # frame request, which is why no chrome comes with it.
  def show
    render partial: "shared/app_notifications", locals: { bell: notification_bell }
  end

  # The bell's one write: everything unread becomes read. Back to wherever the
  # dropdown was open on.
  def read_all
    Current.user.notifications.unread.update_all(read_at: Time.current, updated_at: Time.current)
    # Reading is a change to the bell too, and a student with the app open on a
    # laptop and a phone cleared it on both. This tab gets it from the redirect
    # below; the broadcast is for the others.
    notification_bell.broadcast_refresh!

    redirect_back fallback_location: root_path
  end
end
