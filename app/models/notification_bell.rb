# The bell, as an object that knows how to get itself redrawn.
#
# Notifications are the one thing in this app written *for* somebody by somebody
# else — every `Notification.notify` call is in `AdminController`, and the person
# it concerns is not the person acting. Until now they learned about it on their
# next page load. This is the seam that closes that gap, and it is one class on
# purpose: the DOM id that gets replaced, the channel it is replaced over, the
# path it is re-read from and the two figures it shows all live here, so a caller
# writes
#
#   NotificationBell.new(user).broadcast_refresh!
#
# and needs to know none of them. That is the point of the pattern — the
# alternative spreads a dom id, a stream name and a partial path across the
# header, a broadcast site and a template, where nothing checks they agree.
#
# It is a plain class rather than a component object because this codebase has no
# component layer and does not want one.
#
# == Why the broadcast does not carry the bell
#
# The obvious shape — render the finished bell and push that — does not survive
# this app, for two reasons that a broadcast has in common: **it has no session**.
#
#   * The panel contains the one form this menu has, and a form rendered outside
#     a session gets no CSRF token at all. Measured, not assumed: with forgery
#     protection on, `button_to` in an out-of-band render emits no
#     `authenticity_token`, so a "mark all read" clicked on a pushed bell would
#     be refused — and would look identical to one that worked.
#   * A reader's language lives in `session[:locale]`. A notification is stored
#     as a kind rather than a sentence precisely so it reads in the language of
#     whoever *reads* it, and rendering one in the language of whoever triggered
#     it would quietly undo that.
#
# So the broadcast pushes an empty frame that names its own `src`, and the
# browser comes back for the bell over an ordinary authenticated request — which
# carries the reader's cookies, and therefore their token and their language.
# One extra round trip, on an event that happens a handful of times a term.
class NotificationBell
  # Chrome, one to a page, never a list — so the id is a constant rather than a
  # `dom_id` off a record.
  ID = "notification-bell"

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def id = ID

  # Per user, and nothing else: the pushed frame is the same handful of bytes for
  # everyone, so there is nothing in it to scope any further.
  def stream = [ user, :notifications ]

  def broadcast_refresh!
    Turbo::StreamsChannel.broadcast_replace_to(
      stream, target: id, partial: "shared/app_notifications_refetch"
    )
  end

  # The panel is a sidebar, not an archive.
  def recent = @recent ||= user.notifications.newest_first.limit(Notification::RECENT).to_a

  # Asked of every row rather than of `recent`: an unread notification that has
  # been pushed off the bottom of the panel still deserves the dot.
  def unread?
    return @unread if defined?(@unread)

    @unread = user.notifications.unread.any?
  end
end
