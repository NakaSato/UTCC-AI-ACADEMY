class Session < ApplicationRecord
  # A session dies thirty days after it was created, whether or not it has been
  # used since. The cap is **absolute rather than idle** on purpose: an idle
  # timeout has to touch the row on every authenticated request, and a write per
  # page view is the cost every other decision in the codebase refuses to pay.
  # Postgres would take those writes where SQLite's single writer would not, but
  # the trade is about what the app spends per request, not about what the
  # database can survive — so the cap stays absolute.
  #
  # Thirty days is invisible to normal use, since a student signs in at least
  # weekly through a semester, and it is what bounds a cookie taken from a shared
  # campus machine. Before this, `cookies.signed.permanent` meant twenty years.
  MAX_AGE = 30.days

  belongs_to :user

  # `live` is the only way a session should ever be looked up — see
  # Authentication#find_session_by_cookie and ApplicationCable::Connection.
  scope :live,    -> { where(created_at: MAX_AGE.ago..) }
  scope :expired, -> { where(created_at: ...MAX_AGE.ago) }
end
