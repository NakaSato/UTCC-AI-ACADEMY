require "test_helper"

# The auth screens moved from the generator's REST URLs to plain ones (/login,
# /register, /forgot-password, /reset-password/:token). The old paths stay
# routable so reset links already sitting in inboxes still work.
class LegacyAuthRoutesTest < ActionDispatch::IntegrationTest
  test "the generator's sign-in and sign-up URLs redirect to the new ones" do
    get "/session/new"
    assert_redirected_to "/login"

    get "/registration/new"
    assert_redirected_to "/register"
  end

  test "the generator's password URLs redirect, carrying the token through" do
    get "/passwords/new"
    assert_redirected_to "/forgot-password"

    token = users(:one).password_reset_token
    get "/passwords/#{token}/edit"
    assert_redirected_to "/reset-password/#{token}"
  end

  test "a redirected reset link still reaches the form" do
    token = users(:one).password_reset_token
    get "/passwords/#{token}/edit"
    follow_redirect!
    assert_response :success
    assert_select "form[action=?]", "/reset-password/#{token}", 1
  end
end
