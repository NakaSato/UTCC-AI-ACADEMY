require "test_helper"

class CourseTest < ActiveSupport::TestCase
  test "lifecycle transitions are explicit and persisted" do
    course = courses(:ai1101)

    course.transition_to!(:archived)

    assert_predicate course.reload, :archived?
    assert_equal [ "published" ], Course::TRANSITIONS[:archived]
  end

  test "invalid lifecycle transitions are rejected" do
    course = courses(:ai1101)

    error = assert_raises(ActiveRecord::RecordInvalid) { course.transition_to!(:draft) }

    assert_includes error.record.errors[:lifecycle_state], I18n.t("errors.messages.invalid_transition")
    assert_predicate course.reload, :published?
  end

  test "new courses start as drafts" do
    course = courses(:ai1102)
    course.update!(lifecycle_state: :draft)

    assert_predicate course.reload, :draft?
    assert_equal [ "published" ], course.available_transitions
  end
end
