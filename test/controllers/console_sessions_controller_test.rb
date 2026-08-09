require "test_helper"

# /console is the staff and company way in: a different credential from /login,
# a different set of screens afterwards, and a door that stays shut for a learner
# whose password is perfectly correct.
class ConsoleSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Console Co", creator: users(:admin))
    @recruiter = users(:one)
    @organization.memberships.create!(user: @recruiter, role: "recruiter")
  end

  # Same trick as SessionsControllerTest: the test cache is a :null_store whose
  # `increment` answers nil, so the limiter is inert unless one is lent to it.
  def with_counting_rate_limiter
    store = ConsoleSessionsController.cache_store
    memory = ActiveSupport::Cache::MemoryStore.new
    store.define_singleton_method(:increment) { |*args, **kwargs| memory.increment(*args, **kwargs) }
    yield
  ensure
    store.singleton_class.remove_method(:increment)
  end

  def sign_in_to_console(identifier:, password: "password")
    post console_path, params: { identifier:, password: }
  end

  test "new" do
    get console_path

    assert_response :success
    assert_select "form[action=?]", console_path
    assert_select "input[name=identifier]"
  end

  # The console screen sells the console, not the curriculum — the hero beside
  # the form is the one thing the two sign-in screens do not share.
  test "the console screen carries its own hero copy" do
    get console_path
    assert_select "h1", text: I18n.t("auth.console.hero_title")

    get login_path
    assert_select "h1", text: I18n.t("auth.hero_title")
  end

  # A console account is granted — by an admin for a role, by a company through
  # an invitation — so the screen offers no way to make one.
  test "the console does not offer registration" do
    get console_path

    assert_select "a[href=?]", register_path, false
    assert_select "a[href=?]", login_path
  end

  # The two doors point at each other, or /console is a URL you have to be told
  # about and the people it is for are the last to be told.
  test "the student sign-in points at the console" do
    get login_path

    assert_select "a[href=?]", console_path, text: I18n.t("auth.login.console_link")
  end

  test "an instructor lands on the teaching console" do
    sign_in_to_console identifier: users(:instructor).student_id

    assert_redirected_to instructor_url
    assert cookies[:session_id].present?
  end

  # Admin first, because an admin is staff too and /admin is the wider screen.
  test "an admin lands on the admin console" do
    sign_in_to_console identifier: users(:admin).student_id

    assert_redirected_to admin_url
    assert cookies[:session_id].present?
  end

  test "a company member lands on their organizations" do
    sign_in_to_console identifier: @recruiter.student_id

    assert_redirected_to recruitment_organizations_url
    assert cookies[:session_id].present?
  end

  # The reason the field takes all three: a recruiter thinks of themselves as an
  # email address, not as a 13-digit ID they were issued to make an account.
  test "a company member signs in with their email address" do
    sign_in_to_console identifier: @recruiter.email_address.upcase

    assert_redirected_to recruitment_organizations_url
    assert cookies[:session_id].present?
  end

  # The shape an admin-created account actually has: no student ID at all.
  test "a console account with no student ID signs in by username" do
    instructor = users(:console_instructor)
    assert_nil instructor.student_id

    sign_in_to_console identifier: " CONSOLE-Teacher "

    assert_redirected_to instructor_url
    assert cookies[:session_id].present?
  end

  test "a company account with no student ID signs in by username" do
    partner = users(:console_company)
    @organization.memberships.create!(user: partner, role: "hiring_manager")

    sign_in_to_console identifier: partner.username

    assert_redirected_to recruitment_organizations_url
    assert cookies[:session_id].present?
  end

  # A username that is not one is a failed sign-in, not a lookup on some other
  # column — the branch picks an attribute name and nothing else.
  test "an unknown username is refused" do
    sign_in_to_console identifier: "not-a-real-account"

    assert_redirected_to console_path
    assert_nil cookies[:session_id]
  end

  # A student's password being right is not the question /console asks.
  test "a learner with no console access is refused and gets no session" do
    sign_in_to_console identifier: users(:student).student_id

    assert_redirected_to console_path
    assert_nil cookies[:session_id]
    assert_equal I18n.t("flash.console_login_failed"), flash[:alert]
  end

  test "a revoked company member is refused" do
    @organization.memberships.find_by!(user: @recruiter).update!(status: "revoked")

    sign_in_to_console identifier: @recruiter.student_id

    assert_redirected_to console_path
    assert_nil cookies[:session_id]
  end

  # A wrong password and an account the console is not for have to be
  # indistinguishable, or the screen answers "is this account staff?" for anyone
  # holding a list of student IDs.
  test "a refused account and a wrong password read the same" do
    sign_in_to_console identifier: users(:instructor).student_id, password: "wrong"
    wrong_password = flash[:alert]

    sign_in_to_console identifier: users(:student).student_id
    no_access = flash[:alert]

    assert_equal wrong_password, no_access
    assert_nil cookies[:session_id]
  end

  test "a blank identifier is refused" do
    sign_in_to_console identifier: ""

    assert_redirected_to console_path
    assert_nil cookies[:session_id]
  end

  # The stash `require_authentication` leaves behind still wins: a company member
  # sent to the front door comes back to the screen they asked for.
  test "a deep link survives the trip through the console" do
    get recruitment_organization_path(@organization)
    assert_redirected_to root_path

    sign_in_to_console identifier: @recruiter.student_id

    assert_redirected_to recruitment_organization_url(@organization)
  end

  test "guessing at one console account is throttled across addresses" do
    with_counting_rate_limiter do
      11.times do |i|
        post console_path, params: { identifier: users(:instructor).student_id, password: "wrong" },
                           headers: { "REMOTE_ADDR" => "203.0.113.#{i}" }
      end
    end

    assert_redirected_to console_path
    assert_equal I18n.t("flash.login_throttled"), flash[:alert]
  end
end
