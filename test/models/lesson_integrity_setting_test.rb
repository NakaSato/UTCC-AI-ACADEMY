require "test_helper"

class LessonIntegritySettingTest < ActiveSupport::TestCase
  test "missing settings default to visible" do
    assert LessonIntegritySetting.enabled?(course: courses(:ai1101), topic_key: "1-1")
  end

  test "rows cover the course syllabus in lesson order" do
    rows = LessonIntegritySetting.rows_for(courses(:ai1101))

    assert_equal Syllabus.topic_count("AI1101"), rows.size
    assert_equal %w[ 1-1 1-2 1-3 2-1 ], rows.first(4).map(&:topic_key)
    assert rows.all?(&:enabled)
  end

  test "updates are typed and use optimistic locking" do
    course = courses(:ai1101)

    LessonIntegritySetting.update!(course:, topic_key: "1-1", enabled: false, expected_lock_version: 0)

    assert_not LessonIntegritySetting.enabled?(course:, topic_key: "1-1")
    LessonIntegritySetting.find_by!(course:, topic_key: "1-1").update!(enabled: true)
    assert_raises(ActiveRecord::StaleObjectError) do
      LessonIntegritySetting.update!(course:, topic_key: "1-1", enabled: true, expected_lock_version: 0)
    end
    assert LessonIntegritySetting.enabled?(course:, topic_key: "1-1")
  end

  test "malformed booleans are rejected at the boundary" do
    assert_nil LessonIntegritySetting.parse_boolean("yes")
    assert_equal true, LessonIntegritySetting.parse_boolean("1")
    assert_equal false, LessonIntegritySetting.parse_boolean("false")
  end
end
