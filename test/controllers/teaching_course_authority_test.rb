require "test_helper"

# What a teacher may do to the course they teach, and what they may not
# (ADR-0054, SPEC-0054).
#
# The dashboard was read-only: a roster, a CSV, and a proctoring switch. Course
# authority lived entirely in /admin, and every route there is `allow_only
# :admin`. This gives a teacher their own course and nothing else — bounded by
# the queue ADR-0013 built, which is the part that must survive.
class TeachingCourseAuthorityTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = users(:instructor)
    @section = Section.for_staff(@teacher)
    @course = @section.course
    @course.update!(lifecycle_state: "draft")
  end

  test "a teacher edits the numbers of the course they teach, and it is audited" do
    sign_in_as @teacher

    assert_difference "AuditEvent.count", 1 do
      patch instructor_course_path, params: { course: { credits: 4, projects: 2, hours: 42, level: "advanced" } }
    end

    assert_redirected_to instructor_path(tab: :course)
    @course.reload
    assert_equal 4, @course.credits
    assert_equal "advanced", @course.level
    assert_equal "course_updated", AuditEvent.newest_first.first.action
  end

  # The identity every locale key and completion row is joined by, the state the
  # queue owns, and the two figures that are measured rather than set.
  test "a teacher cannot rename, republish or inflate a course through the form" do
    sign_in_as @teacher
    original = @course.attributes.slice("code", "lifecycle_state", "learners", "rating")

    patch instructor_course_path, params: {
      course: { credits: 4, code: "HACK101", lifecycle_state: "published", learners: 9_999, rating: 5 }
    }

    assert_equal original, @course.reload.attributes.slice("code", "lifecycle_state", "learners", "rating")
    assert_equal 4, @course.credits, "the permitted field still saved"
  end

  test "a published course is not edited here, it goes through the queue" do
    @course.update!(lifecycle_state: "published")
    sign_in_as @teacher

    assert_no_difference "AuditEvent.count" do
      patch instructor_course_path, params: { course: { credits: 9 } }
    end

    assert_equal I18n.t("flash.course_not_editable"), flash[:alert]
    assert_not_equal 9, @course.reload.credits
  end

  # The whole point of ADR-0013, kept: a teacher asks, an administrator decides.
  test "a teacher requests a transition rather than making one" do
    sign_in_as @teacher

    assert_difference "ApprovalRequest.count", 1 do
      post instructor_course_transition_path, params: { state: "published" }
    end

    request = ApprovalRequest.newest_first.first
    assert_equal @teacher, request.requester
    assert_equal "draft", @course.reload.lifecycle_state, "asking must not publish"
    assert_predicate request, :pending?
    assert_not request.approvable_by?(@teacher), "nobody decides their own request"
    assert request.approvable_by?(users(:admin))
  end

  test "another teacher's course is not theirs to touch" do
    other = users(:console_instructor)
    sign_in_as other

    assert_no_difference [ "AuditEvent.count", "ApprovalRequest.count" ] do
      patch instructor_course_path, params: { course: { credits: 9 } }
      post instructor_course_transition_path, params: { state: "published" }
    end

    assert_equal I18n.t("flash.course_not_yours"), flash[:alert]
    assert_not_equal 9, @course.reload.credits
  end

  # An administrator holds the staff role, so the screen opens for them — and
  # they teach nothing, so it offers them no course. Their authority is the
  # console, where it always was.
  test "an administrator teaches nothing and is offered no course panel" do
    sign_in_as users(:admin)
    get instructor_url

    assert_response :success
    assert_select "[data-course-code]", count: 0
    # Not merely closed — absent. The tab is not in the bar, and asking for it by
    # hand opens the roster rather than a panel about somebody else's course.
    assert_select "main nav a", text: /#{I18n.t("instructor.tabs.course")}/, count: 0

    get instructor_url(tab: :course)

    assert_response :success
    assert_select "[data-course-code]", count: 0
    assert_select "main nav a[aria-current=page]", text: /#{I18n.t("instructor.tabs.roster")}/

    assert_no_difference "ApprovalRequest.count" do
      post instructor_course_transition_path, params: { state: "published" }
    end
    assert_equal I18n.t("flash.course_not_yours"), flash[:alert]
  end

  test "a student reaches none of it" do
    sign_in_as users(:one)

    patch instructor_course_path, params: { course: { credits: 9 } }
    assert_redirected_to root_path

    post instructor_course_transition_path, params: { state: "published" }
    assert_redirected_to root_path
  end

  test "the screen shows the course panel to the teacher who teaches it" do
    sign_in_as @teacher
    get instructor_url(tab: :course)

    assert_response :success
    assert_select "[data-course-code=?]", @course.code
    assert_select "form[action=?]", instructor_course_path
    assert_select "form[action=?]", instructor_course_transition_path
  end
end
