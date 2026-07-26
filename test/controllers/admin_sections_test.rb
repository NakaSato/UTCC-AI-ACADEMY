require "test_helper"

# The Sections tab: the three writes a deployment needs before the cohort
# features have anyone in them. Real records, same shape as the role grant.
class AdminSectionsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "the tab lists sections and opens one from the URL" do
    get admin_url(tab: :sections, section: sections(:ba_2).id)

    assert_response :success
    assert_select "main", text: /#{sections(:ba_2).label}/
    assert_select "main", text: /#{users(:one).name}/, minimum: 1
  end

  test "an unknown selection falls back instead of raising" do
    get admin_url(tab: :sections, section: 999_999)

    assert_response :success
  end

  test "an admin creates a section with an instructor" do
    assert_difference -> { Section.count }, 1 do
      post admin_sections_url,
           params: { course_code: "AI1102", code: "EN-1", term: "1/2569",
                     instructor_id: users(:instructor).id }
    end

    section = Section.order(:id).last
    assert_equal "AI1102 · EN-1", section.label
    assert_equal users(:instructor), section.instructor
    assert_redirected_to admin_path(tab: :sections, section: section.id)
  end

  test "a duplicate section comes back as the model's own message" do
    assert_no_difference -> { Section.count } do
      post admin_sections_url,
           params: { course_code: "AI1101", code: "BA-2", term: "1/2569" }
    end

    assert_redirected_to admin_path(tab: :sections)
    assert flash[:alert].present?
  end

  # The select only offers staff, but a forged id must not become a teacher.
  test "a student posted as the instructor is not assigned" do
    post admin_sections_url,
         params: { course_code: "AI1102", code: "EN-2", term: "1/2569",
                   instructor_id: users(:one).id }

    assert_nil Section.order(:id).last.instructor
  end

  test "reassigning the instructor writes and reports it" do
    patch admin_section_url(sections(:ba_2)), params: { instructor_id: users(:admin).id }

    assert_equal users(:admin), sections(:ba_2).reload.instructor
    assert_equal I18n.t("flash.section_updated", label: sections(:ba_2).label), flash[:notice]
  end

  test "enrolling by student ID adds to the roster once" do
    assert_difference -> { Enrollment.count }, 1 do
      post admin_enrol_url(sections(:ba_2)), params: { student_id: users(:two).student_id }
    end

    # Again is a no-op with the same friendly answer, not an error.
    assert_no_difference -> { Enrollment.count } do
      post admin_enrol_url(sections(:ba_2)), params: { student_id: users(:two).student_id }
    end

    assert_equal I18n.t("flash.enrolled", name: users(:two).name, label: sections(:ba_2).label),
                 flash[:notice]
  end

  test "an unknown student ID is a flash, not a crash" do
    assert_no_difference -> { Enrollment.count } do
      post admin_enrol_url(sections(:ba_2)), params: { student_id: "9999999999999" }
    end

    assert_equal I18n.t("flash.student_missing"), flash[:alert]
  end

  test "staff cannot be enrolled as students" do
    assert_no_difference -> { Enrollment.count } do
      post admin_enrol_url(sections(:ba_2)), params: { student_id: users(:instructor).student_id }
    end

    assert flash[:alert].present?
  end

  test "unenrolling removes the student and nothing else" do
    assert_difference -> { Enrollment.count }, -1 do
      delete admin_unenrol_url(sections(:ba_2), users(:one))
    end

    assert_includes sections(:ba_2).reload.students, users(:student)
    assert_predicate users(:one).reload, :persisted?, "removing an enrolment must not touch the account"
  end

  test "the whole tab takes the admin role" do
    sign_in_as users(:instructor)

    post admin_sections_url, params: { course_code: "AI1101", code: "X-1", term: "1/2569" }
    assert_response :redirect
    assert_equal 0, Section.where(code: "X-1").count
  end
end
