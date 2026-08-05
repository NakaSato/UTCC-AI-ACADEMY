require "test_helper"

class SessionManagementTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "the profile lists only the current user's minimized active sessions" do
    other = users(:one).sessions.create!(user_agent: "Mozilla/5.0 (Android)", ip_address: "192.0.2.10")
    stranger = users(:two).sessions.create!(user_agent: "private-stranger-agent", ip_address: "198.51.100.8")

    get profile_url

    assert_response :success
    assert_select "main h2", text: I18n.t("profile.sessions.title")
    assert_select "form[action=?]", revoke_profile_session_path(other.revoke_token), count: 1
    assert_no_match(/private-stranger-agent|192\.0\.2\.10|198\.51\.100\.8/, response.body)
    assert_no_match(/#{Regexp.escape(revoke_profile_session_path(stranger.revoke_token))}/, response.body)
  end

  test "a learner can revoke one other session without revoking the current one" do
    other = users(:one).sessions.create!(user_agent: "Mozilla/5.0 (Windows NT 10.0)")
    current = Current.session

    delete revoke_profile_session_path(other.revoke_token)

    assert_redirected_to profile_url
    assert_equal I18n.t("flash.session_revoked"), flash[:notice]
    assert_not Session.exists?(other.id)
    assert Session.exists?(current.id)
  end

  test "a learner can revoke all other sessions but not the current one" do
    first = users(:one).sessions.create!
    second = users(:one).sessions.create!
    current = Current.session

    delete revoke_other_sessions_path

    assert_redirected_to profile_url
    assert_equal I18n.t("flash.other_sessions_revoked"), flash[:notice]
    assert_not Session.exists?(first.id)
    assert_not Session.exists?(second.id)
    assert Session.exists?(current.id)
  end

  test "a current-session or cross-account token cannot revoke anything" do
    other = users(:one).sessions.create!
    stranger = users(:two).sessions.create!

    [ Current.session.revoke_token, stranger.revoke_token ].each do |token|
      delete revoke_profile_session_path(token)

      assert_redirected_to profile_url
      assert_equal I18n.t("flash.session_revoke_invalid"), flash[:alert]
    end

    assert Session.exists?(other.id)
    assert Session.exists?(stranger.id)
    assert Session.exists?(Current.session.id)
  end

  test "an expired session is not an active-session revocation target" do
    expired = users(:one).sessions.create!(created_at: Session::MAX_AGE.ago - 1.second)
    first = users(:one).sessions.create!
    token = expired.revoke_token

    delete revoke_profile_session_path(token)

    assert_redirected_to profile_url
    assert_equal I18n.t("flash.session_revoke_invalid"), flash[:alert]
    assert Session.exists?(expired.id)

    delete revoke_other_sessions_path

    assert_not Session.exists?(first.id)
    assert Session.exists?(expired.id)
  end

  test "a revoked session cookie fails the ordinary authentication boundary" do
    revoked = users(:one).sessions.create!
    cookie = signed_cookie_for(revoked)
    revoked.destroy!
    cookies["session_id"] = cookie

    get my_learning_path

    assert_redirected_to root_path
    assert_equal I18n.t("flash.sign_in_required"), flash[:alert]
  end

  private
    def signed_cookie_for(session)
      ActionDispatch::TestRequest.create.cookie_jar.tap do |jar|
        jar.signed[:session_id] = session.id
      end[:session_id]
    end
end
