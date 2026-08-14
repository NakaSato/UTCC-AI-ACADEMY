require "test_helper"

# What a student may do with an AI assistant in one lesson, said out loud on the
# lesson itself. A sibling of LessonIntegritySetting, not a column on it: that
# decides whether the proctor log is *shown*, this decides what is *allowed*, and
# neither implies the other.
class LessonAiPolicyTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = users(:instructor)
    @course = courses(:ai1101)
    @topic_key = "1-1"
  end

  # ---- The default ----------------------------------------------------------

  # Not `allowed`, which would make the panel decoration, and not `forbidden`,
  # which would make every unconsidered lesson a trap.
  test "an unset lesson reads allowed-but-say-so, and stores nothing" do
    rows = LessonAiPolicy.rows_for(course: @course, topic_key: @topic_key)

    assert_equal LessonAiPolicy::USES, rows.map(&:use_key)
    assert rows.all? { it.stance == "disclose" }
    assert_empty LessonAiPolicy.all, "reading a default must not write one"
  end

  test "every use and every stance is named in both languages" do
    %i[ en th ].each do |locale|
      LessonAiPolicy::USES.each do |use|
        assert I18n.t("lesson.ai.uses.#{use}", locale:, default: nil).present?, "#{locale} missing use #{use}"
      end
      LessonAiPolicy::STANCES.each do |stance|
        assert I18n.t("lesson.ai.stances.#{stance}", locale:, default: nil).present?
      end
      assert I18n.t("lesson.ai.title", locale:, default: nil).present?
    end
  end

  # ---- The lesson -----------------------------------------------------------

  test "the lesson states the rule, and states it as words rather than a colour" do
    LessonAiPolicy.create!(course: @course, topic_key: @topic_key, use_key: "draft", stance: "forbidden")
    sign_in_as users(:one)

    get lesson_url(topic: @topic_key)

    assert_response :success
    assert_select "main h3", text: I18n.t("lesson.ai.title")
    assert_select "main", text: /#{I18n.t("lesson.ai.uses.draft")}/
    # The stance is written next to the dot: a colour is not a sentence, and this
    # is the one panel that must not be ambiguous.
    assert_select "main", text: /#{I18n.t("lesson.ai.stances.forbidden")}/
  end

  test "a teacher reading their own lesson sees the rule their students are held to" do
    sign_in_as @teacher

    get lesson_url(topic: @topic_key)

    assert_response :success
    assert_select "main h3", text: I18n.t("lesson.ai.title")
  end

  # ---- The teacher's control ------------------------------------------------

  test "a teacher sets a stance, and it is audited" do
    sign_in_as @teacher

    assert_difference "AuditEvent.count", 1 do
      patch instructor_ai_policy_path(@topic_key, "draft"), params: { stance: "forbidden", lock_version: 0 }
    end

    assert_redirected_to instructor_path(tab: :integrity)
    assert_equal "forbidden", LessonAiPolicy.stance_for(course: @course, topic_key: @topic_key, use_key: "draft")
    event = AuditEvent.newest_first.first
    assert_equal "lesson_ai_policy_changed", event.action
    assert_equal :warn, event.level, "a rule a learner is held to is worth a second look"
    assert_no_match(/[{}]/, event.text)
  end

  test "the integrity tab offers a control per use, per lesson" do
    sign_in_as @teacher

    get instructor_url(tab: :integrity)

    assert_response :success
    LessonAiPolicy::USES.each do |use|
      assert_select "form[action=?]", instructor_ai_policy_path(@topic_key, use)
    end
    # A select and a submit, never a select that submits itself: script-src is
    # `self` with a nonce and no unsafe-inline, so an inline handler would be
    # refused by the CSP and the control would silently do nothing.
    assert_select "form select[name=stance]"
    assert_select "[onchange]", count: 0
  end

  test "a stance nobody defined, and a use nobody defined, are refused" do
    sign_in_as @teacher

    patch instructor_ai_policy_path(@topic_key, "draft"), params: { stance: "whatever", lock_version: 0 }
    assert_equal I18n.t("flash.integrity_setting_invalid"), flash[:alert]

    patch instructor_ai_policy_path(@topic_key, "telepathy"), params: { stance: "allowed", lock_version: 0 }
    assert_equal I18n.t("flash.integrity_setting_invalid"), flash[:alert]

    assert_empty LessonAiPolicy.all
  end

  test "another course's lesson is not this teacher's to rule on" do
    sign_in_as @teacher

    patch instructor_ai_policy_path("AI1102-1-1", "draft"), params: { stance: "forbidden", lock_version: 0 }

    assert_equal I18n.t("flash.integrity_setting_forbidden"), flash[:alert]
    assert_empty LessonAiPolicy.all
  end

  test "a stale write is refused rather than overwriting a newer rule" do
    # Twice: `lock_version` is a real optimistic-locking column, so the create
    # leaves it at 0 and only the second write moves it to 1. One write would
    # have made this test pass against a version that was never stale.
    LessonAiPolicy.update!(course: @course, topic_key: @topic_key, use_key: "draft",
                           stance: "allowed", expected_lock_version: 0)
    LessonAiPolicy.update!(course: @course, topic_key: @topic_key, use_key: "draft",
                           stance: "forbidden", expected_lock_version: 0)
    sign_in_as @teacher

    patch instructor_ai_policy_path(@topic_key, "draft"), params: { stance: "allowed", lock_version: 0 }

    assert_equal I18n.t("flash.integrity_setting_stale"), flash[:alert]
    assert_equal "forbidden", LessonAiPolicy.stance_for(course: @course, topic_key: @topic_key, use_key: "draft")
  end

  test "a student cannot set the rule they are held to" do
    sign_in_as users(:one)

    patch instructor_ai_policy_path(@topic_key, "draft"), params: { stance: "allowed", lock_version: 0 }

    assert_redirected_to root_path
    assert_empty LessonAiPolicy.all
  end

  # ---- What it is not -------------------------------------------------------

  # The two settings are siblings, and a teacher may perfectly well allow an
  # assistant and still hide the log, or forbid it and show it.
  test "the AI rule and the proctor log are independent" do
    LessonIntegritySetting.update!(course: @course, topic_key: @topic_key, enabled: false,
                                   expected_lock_version: 0)
    LessonAiPolicy.create!(course: @course, topic_key: @topic_key, use_key: "explain", stance: "allowed")

    assert_not LessonIntegritySetting.enabled?(course: @course, topic_key: @topic_key)
    assert_equal "allowed", LessonAiPolicy.stance_for(course: @course, topic_key: @topic_key, use_key: "explain")
  end
end
