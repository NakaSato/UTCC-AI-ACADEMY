class NotificationsController < ApplicationController
  # What was I told? The bell answers what is waiting — the dot — and until this
  # screen existed nothing answered the other question: `Notification::RECENT`
  # is eight and no route reached the ninth, on the only channel there is while
  # ADR-0004 defers production email.
  #
  # Paged like every other list that grows with the institution (ADR-0050), and
  # a history rather than an inbox: read rows stay, because a list that empties
  # as you read it answers the question the dot already answered.
  #
  # **Reading this page marks nothing read.** That stays the explicit action on
  # the button the bell already has (ADR-0052 decision 3): a dot that clears by
  # being looked at means "you have not visited" rather than "something
  # happened", and would silently dismiss the seven the reader did not come for.
  def show
    @notifications = Page.new(Current.user.notifications.newest_first, params[:page])
  end

  # The bell, alone. This is what the frame a broadcast pushes comes back for, and
  # the whole reason the broadcast pushes a frame instead of the bell itself: an
  # ordinary request has the reader's session, so the copy is in their language
  # and the panel's form carries a token they can actually submit.
  #
  # It renders the same partial the header does, so the pushed bell and the loaded
  # one cannot drift apart. turbo-rails swaps in its own minimal layout for a
  # frame request, which is why no chrome comes with it.
  def bell
    render partial: "shared/app_notifications", locals: { bell: notification_bell }
  end

  # The bell's one write: everything unread becomes read.
  #
  # Clearing a dropdown is not a navigation, and it used to be one — the redirect
  # was there only so the bell would be redrawn and so something would say it
  # had worked. A Turbo request gets both without leaving the page: the bell is
  # replaced in this response and the toast says what happened. A browser
  # without JS still gets the redirect, which is the same answer as before.
  def read_all
    Current.user.notifications.unread.update_all(read_at: Time.current, updated_at: Time.current)
    # Reading is a change to the bell too, and a student with the app open on a
    # laptop and a phone cleared it on both. The broadcast is for the others;
    # this tab is answered directly, because a bell that clears itself only once
    # the websocket comes back would leave the dot sitting under a toast saying
    # it was gone.
    notification_bell.broadcast_refresh!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(notification_bell.id, partial: "shared/app_notifications",
                                                     locals: { bell: notification_bell }),
          turbo_stream.toast(t("flash.notifications_read"), kind: :success)
        ]
      end
      format.html { redirect_back fallback_location: root_path }
    end
  end
end
