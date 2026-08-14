require "test_helper"
require "action_cable/connection/test_case"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  tests ApplicationCable::Connection

  setup { @session = users(:one).sessions.create! }

  test "connects with a live session cookie" do
    cookies.signed[:session_id] = @session.id

    connect

    assert_equal users(:one), connection.current_user
  end

  test "rejects a revoked session cookie" do
    cookies.signed[:session_id] = @session.id
    @session.destroy!

    assert_reject_connection { connect }
  end

  test "rejects a session older than Session::MAX_AGE" do
    @session.update_column(:created_at, (Session::MAX_AGE + 1.day).ago)
    cookies.signed[:session_id] = @session.id

    assert_reject_connection { connect }
  end

  # The half a check on the HTTP side alone would miss. Every signed-in page
  # subscribes the notification bell, so a suspended account with a live cookie
  # would otherwise keep a socket open on a screen it can no longer load.
  test "rejects a live session whose account has been suspended" do
    users(:one).update!(suspended_at: Time.current)
    cookies.signed[:session_id] = @session.id

    assert_reject_connection { connect }
  end

  test "accepts it again once the account is restored" do
    users(:one).update!(suspended_at: Time.current)
    users(:one).update!(suspended_at: nil)
    cookies.signed[:session_id] = @session.id

    connect

    assert_equal users(:one), connection.current_user
  end

  # Authentication#find_session_by_cookie and this method resolve the same
  # cookie, and the comment on each has always said they have to match. This is
  # that claim as a test rather than as a comment.
  test "both cookie readers resolve through the same scope" do
    source = File.read(Rails.root.join("app/controllers/concerns/authentication.rb"))
    cable = File.read(Rails.root.join("app/channels/application_cable/connection.rb"))

    assert_match(/Session\.usable\.find_by\(id: cookies\.signed\[:session_id\]\)/, source)
    assert_match(/Session\.usable\.find_by\(id: cookies\.signed\[:session_id\]\)/, cable)
  end
end
