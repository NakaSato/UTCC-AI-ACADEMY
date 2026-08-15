require "test_helper"

class AuthSwitchTest < ActionDispatch::IntegrationTest
  test "login page ships both panels with login visible" do
    get login_url
    assert_select "section[data-panel=login]:not([hidden])", 1
    assert_select "section[data-panel=register][hidden]", 1
    assert_select "button[role=tab][data-panel=login][aria-selected=true]", 1
    assert_select "button[role=tab][data-panel=register][aria-selected=false]", 1
    assert_select "button[role=tab][data-auth-tab][data-tab-motion]", 2
    assert_select "section[data-panel=login] input[autofocus]", 1
    assert_select "section[data-panel=register] input[autofocus]", 0
    assert_select "form[action=?]", "/login", 1
    assert_select "form[action=?]", "/register", 1
  end

  test "register page opens on the register panel" do
    get register_url
    assert_select "section[data-panel=register]:not([hidden])", 1
    assert_select "section[data-panel=login][hidden]", 1
    assert_select "button[role=tab][data-panel=register][aria-selected=true]", 1
    assert_select "section[data-panel=register] input[autofocus]", 1
  end

  test "failed sign-up re-renders on the register panel with errors" do
    post register_url, params: { user: { name: "x", student_id: "2011071730013",
      password: "short", password_confirmation: "short" } }
    assert_response :unprocessable_entity
    assert_select "section[data-panel=register]:not([hidden]) div[role=alert]", 1
  end
end
