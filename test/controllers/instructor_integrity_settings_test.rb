require "test_helper"

class InstructorIntegritySettingsTest < ActionDispatch::IntegrationTest
  test "an instructor can hide a lesson log for the assigned course" do
    sign_in_as users(:instructor)
    get instructor_url

    assert_response :success
    assert_select "form[action=?]", instructor_integrity_setting_path("1-1")
    assert_select "main", text: /#{I18n.t("instructor.integrity_settings_title")}/

    patch instructor_integrity_setting_url("1-1"),
          params: { enabled: "false", lock_version: 0 }

    assert_redirected_to instructor_path
    assert_not LessonIntegritySetting.enabled?(course: courses(:ai1101), topic_key: "1-1")
    assert_equal "lesson_integrity_setting_changed", AuditEvent.sole.action
    assert_equal :warn, AuditEvent.sole.level

    sign_in_as users(:one)
    get lesson_url(topic: "1-1")

    assert_response :success
    assert_select "main[data-controller*=proctor]", 1
    assert_select "main", text: /#{I18n.t("lesson.proctor.events_title")}/, count: 0
  end

  test "events continue recording when the student log is hidden" do
    LessonIntegritySetting.update!(course: courses(:ai1101), topic_key: "1-1", enabled: false, expected_lock_version: 0)

    sign_in_as users(:one)
    post lesson_incident_url, params: { kind: "blur", course: "AI1101", topic: "1-1" }

    assert_response :created
    assert_equal 1, ProctorEvent.count
  end

  test "an instructor cannot change another course's lesson setting" do
    sign_in_as users(:instructor)

    patch instructor_integrity_setting_url("AI1102-1-1"),
          params: { enabled: "false", lock_version: 0 }

    assert_redirected_to instructor_path
    assert_equal I18n.t("flash.integrity_setting_forbidden"), flash[:alert]
    assert_empty LessonIntegritySetting.all
    assert_empty AuditEvent.all
  end

  test "stale or malformed updates do not write" do
    sign_in_as users(:instructor)

    patch instructor_integrity_setting_url("1-1"),
          params: { enabled: "maybe", lock_version: 0 }
    assert_equal I18n.t("flash.integrity_setting_invalid"), flash[:alert]
    assert_empty LessonIntegritySetting.all

    LessonIntegritySetting.update!(course: courses(:ai1101), topic_key: "1-1", enabled: false, expected_lock_version: 0)
    LessonIntegritySetting.find_by!(course: courses(:ai1101), topic_key: "1-1").update!(enabled: true)
    patch instructor_integrity_setting_url("1-1"),
          params: { enabled: "true", lock_version: 0 }

    assert_equal I18n.t("flash.integrity_setting_stale"), flash[:alert]
    assert LessonIntegritySetting.enabled?(course: courses(:ai1101), topic_key: "1-1")
    assert_empty AuditEvent.all
  end
end
