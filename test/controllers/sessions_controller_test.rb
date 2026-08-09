require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:student) }

  # The test environment's cache is a :null_store, whose `increment` answers nil,
  # so every rate limit in the app is inert here. `rate_limit` captures the store
  # when the class is loaded, which is why this lends that one object a real
  # MemoryStore's `increment` for the length of a block rather than changing
  # config.cache_store — turning the limiter on for the whole suite would fail
  # any file that signs in eleven times, for reasons unrelated to what it tests.
  def with_counting_rate_limiter
    store = SessionsController.cache_store
    memory = ActiveSupport::Cache::MemoryStore.new
    store.define_singleton_method(:increment) { |*args, **kwargs| memory.increment(*args, **kwargs) }
    yield
  ensure
    store.singleton_class.remove_method(:increment)
  end

  def failed_login(student_id:, ip:)
    post login_path, params: { student_id:, password: "wrong" }, headers: { "REMOTE_ADDR" => ip }
  end

  test "new" do
    get login_path
    assert_response :success
  end

  test "the auth footer links to contributors and proposal ideas in both locales" do
    %w[th en].each do |locale|
      post language_path(locale)
      get login_path

      assert_response :success
      assert_select "footer a[href=?]", contributors_path, 1
      assert_select "footer a[href=?]", new_proposal_request_path, 1
      assert_select "footer a", { text: I18n.t("chrome.footer.columns.community.links.contributors", locale:), count: 1 }
      assert_select "footer a", { text: I18n.t("chrome.footer.columns.community.links.proposal", locale:), count: 1 }
    end
  end

  test "create with valid credentials" do
    post login_path, params: { student_id: @user.student_id, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  # One sign-in screen for everyone: authentication is role-agnostic, and what a
  # role changes is only which screens open afterwards.
  test "every role signs in through the same form" do
    [ users(:student), users(:instructor), users(:admin) ].each do |user|
      post login_path, params: { student_id: user.student_id, password: "password" }

      assert_redirected_to root_path, "#{user.role} should be able to sign in"
      assert(cookies[:session_id].present?, "#{user.role} should get a session")

      delete logout_path
    end
  end

  test "create with invalid credentials" do
    post login_path, params: { student_id: @user.student_id, password: "wrong" }

    assert_redirected_to login_path
    assert_nil cookies[:session_id]
  end

  test "create with an email address in the student ID field" do
    post login_path, params: { student_id: users(:one).email_address, password: "password" }

    assert_redirected_to login_path
    assert_nil cookies[:session_id]
  end

  test "create with a blank student ID" do
    post login_path, params: { student_id: "", password: "password" }

    assert_redirected_to login_path
    assert_nil cookies[:session_id]
  end

  # The point of the account-keyed limit: an IP-only one is no obstacle to
  # someone guessing at one account from many addresses, which is exactly the
  # shape of an attack run off a list of real student IDs.
  test "guessing at one account is throttled even from a different IP each time" do
    with_counting_rate_limiter do
      10.times { |i| failed_login(student_id: @user.student_id, ip: "203.0.113.#{i}") }
      failed_login(student_id: @user.student_id, ip: "203.0.113.99")
    end

    assert_redirected_to login_path
    assert_equal I18n.t("flash.login_throttled"), flash[:alert]
  end

  # And the original limit still stands on its own: one machine working through
  # a list of accounts never repeats a student ID, so only the IP key catches it.
  test "working through a list of accounts from one IP is throttled" do
    with_counting_rate_limiter do
      10.times { |i| failed_login(student_id: "201107173000#{i}", ip: "198.51.100.7") }
      failed_login(student_id: "2011071730099", ip: "198.51.100.7")
    end

    assert_equal I18n.t("flash.login_throttled"), flash[:alert]
  end

  # Two limits, two keys — one account being locked out must not lock out the
  # rest of a shared campus network, and vice versa.
  test "a throttled account does not throttle a different one" do
    with_counting_rate_limiter do
      11.times { |i| failed_login(student_id: @user.student_id, ip: "203.0.113.#{i}") }
      failed_login(student_id: users(:one).student_id, ip: "203.0.113.200")
    end

    assert_not_equal I18n.t("flash.login_throttled"), flash[:alert]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete logout_path

    assert_redirected_to login_path
    assert_empty cookies[:session_id]
  end
end
