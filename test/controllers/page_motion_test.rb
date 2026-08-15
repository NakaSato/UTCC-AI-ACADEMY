require "test_helper"

# The controller belongs to the layouts, not to an individual screen: ordinary
# app navigation and the deliberately chrome-free authentication flow should
# share the same restrained content entrance without duplicating view wiring.
class PageMotionTest < ActionDispatch::IntegrationTest
  test "the application layout opts its primary content into page motion" do
    get root_path

    assert_response :success
    assert_select "body[data-controller~=page-motion] main#main", count: 1
  end

  test "the authentication layout uses the same page motion boundary" do
    get login_path

    assert_response :success
    assert_select "body[data-controller~=page-motion] main#main", count: 1
  end
end
