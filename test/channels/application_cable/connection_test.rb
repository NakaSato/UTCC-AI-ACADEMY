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
end
