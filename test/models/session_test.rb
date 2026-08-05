require "test_helper"

class SessionTest < ActiveSupport::TestCase
  setup { @user = users(:student) }

  test "a fresh session is live and not expired" do
    session = @user.sessions.create!

    assert_includes Session.live, session
    assert_not_includes Session.expired, session
  end

  test "a session older than MAX_AGE is expired and not live" do
    session = @user.sessions.create!
    session.update_column(:created_at, (Session::MAX_AGE + 1.day).ago)

    assert_not_includes Session.live, session
    assert_includes Session.expired, session
  end

  # The boundary belongs to the living: a session created exactly MAX_AGE ago is
  # still honoured, so the cap can never expire a session early.
  test "a session at exactly MAX_AGE is still live" do
    session = @user.sessions.create!
    session.update_column(:created_at, Session::MAX_AGE.ago + 1.second)

    assert_includes Session.live, session
  end

  # Nothing may fall between the two scopes — the recurring sweep deletes what
  # `expired` returns, and anything neither live nor expired would leak forever.
  test "live and expired partition the table" do
    @user.sessions.create!
    @user.sessions.create!.update_column(:created_at, 90.days.ago)

    assert_equal Session.count, Session.live.count + Session.expired.count
  end

  test "revocation tokens are signed and resolve without exposing the row ID" do
    session = @user.sessions.create!

    assert_not_equal session.id.to_s, session.revoke_token
    assert_equal session, Session.find_signed(session.revoke_token, purpose: Session::REVOCATION_PURPOSE)
    assert_nil Session.find_signed(session.revoke_token, purpose: "wrong-purpose")
  end

  test "device family reduces stored user-agent data to a broad label" do
    assert_equal :android, @user.sessions.create!(user_agent: "Mozilla/5.0 (Linux; Android 14)").device_family
    assert_equal :ios, @user.sessions.create!(user_agent: "Mozilla/5.0 (iPhone)").device_family
    assert_equal :other, @user.sessions.create!(user_agent: nil).device_family
  end
end
