require "test_helper"

# The cookie-to-record seam, on the axis of time. Session::MAX_AGE is only worth
# anything if `require_authentication` actually stops honouring the cookie, so
# these drive it through a real request rather than asserting on the scope.
class SessionExpiryTest < ActionDispatch::IntegrationTest
  setup { @user = users(:student) }

  test "a session inside the window still opens a gated screen" do
    sign_in_as(@user)

    get my_learning_path

    assert_response :success
  end

  test "a session past MAX_AGE no longer authenticates" do
    sign_in_as(@user)
    Current.session.update_column(:created_at, (Session::MAX_AGE + 1.day).ago)

    get my_learning_path

    assert_redirected_to root_path
    assert_equal I18n.t("flash.sign_in_required"), flash[:alert]
  end

  # An expired session is indistinguishable from never having signed in — there
  # is no separate copy for it, and no hint that the id was ever real.
  test "an expired session is turned away exactly like a signed-out visitor" do
    sign_in_as(@user)
    Current.session.update_column(:created_at, 90.days.ago)
    get my_learning_path
    expired = [ response.status, response.location, flash[:alert] ]

    sign_out
    get my_learning_path

    assert_equal expired, [ response.status, response.location, flash[:alert] ]
  end

  # The row survives the request that was refused — reaping is the recurring
  # job's business, not the request's, and a request that deleted rows would be
  # a write on a read path.
  test "an expired session is not destroyed by being refused" do
    sign_in_as(@user)
    session = Current.session
    session.update_column(:created_at, 90.days.ago)

    get my_learning_path

    assert Session.exists?(session.id)
  end

  test "remember me sets a cookie that expires with the record, not in twenty years" do
    post login_path, params: { student_id: @user.student_id, password: "password", remember_me: "1" }

    expires = cookies.get_cookie("session_id").expires

    assert_not_nil expires, "remember me should still outlive the browser session"
    assert_in_delta Session::MAX_AGE.from_now.to_i, expires.to_i, 1.hour.to_i
  end

  test "without remember me the cookie lasts only as long as the browser session" do
    post login_path, params: { student_id: @user.student_id, password: "password" }

    assert_nil cookies.get_cookie("session_id").expires
  end
end
