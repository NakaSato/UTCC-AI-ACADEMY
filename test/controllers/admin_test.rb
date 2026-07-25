require "test_helper"

# The admin screen is the only place a role is granted — sign-up always produces
# a student. These tests cover who may open it and what the role change refuses.
class AdminTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "the screen lists every account with its role" do
    get admin_url

    assert_response :success
    assert_select "h1", text: I18n.t("admin.title")
    assert_select "main", text: /#{users(:student).student_id}/
    assert_select "main form[action=?]", admin_user_path(users(:student))
  end

  test "an admin promotes a student to instructor" do
    patch admin_user_url(users(:student)), params: { role: "instructor" }

    assert_redirected_to admin_path
    assert_equal("instructor", users(:student).reload.role)
    assert_equal(
      I18n.t("flash.role_changed", name: users(:student).name, role: I18n.t("admin.roles.instructor")),
      flash[:notice]
    )
  end

  test "an unknown role changes nothing" do
    patch admin_user_url(users(:student)), params: { role: "wizard" }

    assert_redirected_to admin_path
    assert_equal(I18n.t("flash.role_invalid"), flash[:alert])
    assert_equal("student", users(:student).reload.role)
  end

  # Only an admin reaches this action, so refusing self-changes is what keeps the
  # last admin from demoting the site into having none.
  test "an admin cannot change their own role" do
    patch admin_user_url(users(:admin)), params: { role: "student" }

    assert_redirected_to admin_path
    assert_equal(I18n.t("flash.role_self"), flash[:alert])
    assert_equal("admin", users(:admin).reload.role)
  end

  test "the admin's own row offers no control" do
    get admin_url

    assert_response :success
    assert_select "form[action=?]", admin_user_path(users(:admin)), count: 0
    assert_select "main", text: /#{I18n.t("admin.role_self")}/
  end

  test "a student cannot change roles by posting straight to the endpoint" do
    sign_in_as users(:student)
    patch admin_user_url(users(:two)), params: { role: "admin" }

    assert_redirected_to root_path
    assert_equal(I18n.t("flash.forbidden"), flash[:alert])
    assert_equal("student", users(:two).reload.role)
  end

  test "an instructor cannot change roles either" do
    sign_in_as users(:instructor)
    patch admin_user_url(users(:two)), params: { role: "admin" }

    assert_redirected_to root_path
    assert_equal("student", users(:two).reload.role)
  end

  test "signing out closes both the screen and the endpoint" do
    sign_out

    get admin_url
    assert_redirected_to login_path

    patch admin_user_url(users(:two)), params: { role: "admin" }
    assert_redirected_to login_path
    assert_equal("student", users(:two).reload.role)
  end
end
