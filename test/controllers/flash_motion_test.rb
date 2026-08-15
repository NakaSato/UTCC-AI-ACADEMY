require "test_helper"

# Redirect feedback is rendered by one shared partial in both layouts. Its
# motion hook belongs to that boundary, while the message, urgency and lifetime
# remain the controller action's responsibility.
class FlashMotionTest < ActionDispatch::IntegrationTest
  test "a rendered flash stack opts each message into shared motion" do
    get reset_password_path("invalid-token")
    follow_redirect!

    assert_select "[data-controller~=flash-motion]" \
                  "[data-action*='turbo:before-cache@document->flash-motion#remove']" do
      assert_select "[data-flash-motion-target=item][role=status]", count: 1
    end
  end

  test "a page without redirect feedback renders no empty motion host" do
    get login_path

    assert_response :success
    assert_select "[data-controller~=flash-motion]", count: 0
  end
end
