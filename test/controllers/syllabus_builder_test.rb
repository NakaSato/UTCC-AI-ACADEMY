require "test_helper"

# The two edits a teacher may make to their own draft syllabus, and the four they
# may not. The naming half rests on SyllabusText — see syllabus_text_test.rb for
# why a reorder used to rename every lesson below it.
class SyllabusBuilderTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = users(:instructor)
    @course = Section.for_staff(@teacher).course
    @course.update!(lifecycle_state: "draft")
    @first, @second = topics(:topic_1_1), topics(:topic_1_2)
    Syllabus.reload!
    SyllabusText.forget
  end

  teardown { Syllabus.reload! }

  test "the tab draws every module and every lesson in order" do
    sign_in_as @teacher
    get instructor_url(tab: :syllabus)

    assert_response :success
    assert_select "main h2", text: I18n.t("instructor.syllabus_title")
    Syllabus.topic_keys(@course.code).each { assert_select "[data-topic-key=?]", it }
    assert_select "form[action=?]", instructor_syllabus_topic_path(@first.key)
    assert_select "form[action=?]", instructor_syllabus_move_path(@second.key)
  end

  # Not audited, and deliberately: AuditEvent leaves the landing page's card
  # reorder out of ACTIONS because it changes neither what exists nor who can do
  # what, and a log full of it buries the role grants. Renaming and reordering a
  # lesson are the same kind of edit. Adding and removing one is not, and that is
  # the half that goes through the queue.
  test "a teacher renames a lesson in both languages, and it is not audited" do
    sign_in_as @teacher

    assert_no_difference "AuditEvent.count" do
      patch instructor_syllabus_topic_path(@first.key),
            params: { names: { en: "Renamed in English", th: "เปลี่ยนชื่อแล้ว" } }
    end

    assert_redirected_to instructor_path(tab: :syllabus)
    Syllabus.reload!
    SyllabusText.forget
    I18n.with_locale(:en) { assert_equal "Renamed in English", Syllabus.topic_name(@first.key, @course.code) }
    I18n.with_locale(:th) { assert_equal "เปลี่ยนชื่อแล้ว", Syllabus.topic_name(@first.key, @course.code) }
  end

  # The property the whole SyllabusText move bought.
  test "moving a lesson moves it without moving anyone's name" do
    sign_in_as @teacher
    names = Syllabus.topic_keys(@course.code).to_h { [ it, Syllabus.topic_name(it, @course.code) ] }

    patch instructor_syllabus_move_path(@second.key), params: { direction: "up" }

    assert_redirected_to instructor_path(tab: :syllabus)
    Syllabus.reload!
    assert_equal 1, @second.reload.position
    assert_equal 2, @first.reload.position
    names.each do |key, was|
      assert_equal was, Syllabus.topic_name(key, @course.code), "#{key} changed name when a lesson moved"
    end
  end

  test "a lesson keeps the key its progress is joined by" do
    sign_in_as @teacher
    before = Topic.in_syllabus_order(@course.code).pluck(:key).sort

    patch instructor_syllabus_move_path(@second.key), params: { direction: "up" }

    assert_equal before, Topic.in_syllabus_order(@course.code).pluck(:key).sort,
                 "a reorder that rewrote keys would detach every completion from its lesson"
  end

  # A reorder that the teacher can see but the learner cannot is not a reorder.
  # `CourseModule#topics` is ordered by position, so moving a lesson moves the
  # sequence "continue where you left off" walks, and the order a course page
  # lists — while the key that learner's progress is joined by does not move.
  test "a reorder moves the sequence a learner is walked through" do
    sign_in_as @teacher
    before = Syllabus.topic_keys(@course.code)

    patch instructor_syllabus_move_path(@second.key), params: { direction: "up" }
    Syllabus.reload!

    after = Syllabus.topic_keys(@course.code)
    assert_equal before.sort, after.sort, "a reorder adds and drops nothing"
    assert_not_equal before, after, "and it does change the order"
    assert_equal @second.key, after.first
    assert_equal @second.key, Syllabus.next_topic_key(Set.new, @course.code),
                 "a learner with nothing finished starts at the lesson now placed first"
    assert_equal @first.key, Syllabus.topic_after(@second.key, @course.code)
  end

  test "a learner's finished lesson survives the reorder that moved it" do
    student = users(:one)
    TopicCompletion.find_or_create_by!(user: student, course: @course, topic: @second) do
      it.learned_at = Time.current
    end
    sign_in_as @teacher

    patch instructor_syllabus_move_path(@second.key), params: { direction: "up" }
    Syllabus.reload!

    done = TopicCompletion.where(user: student, course: @course).includes(:topic).map { it.topic.key }
    assert_includes done, @second.key, "the completion still points at the lesson it was earned on"
    assert_not_equal @second.key, Syllabus.next_topic_key(done.to_set, @course.code),
                     "and it is still counted as finished"
  end

  test "the ends of a module refuse to move further" do
    sign_in_as @teacher

    assert_no_difference "AuditEvent.count" do
      patch instructor_syllabus_move_path(@first.key), params: { direction: "up" }
    end

    assert_equal I18n.t("flash.topic_not_moved"), flash[:alert]
    assert_equal 1, @first.reload.position
  end

  test "a blank name is refused rather than stored" do
    sign_in_as @teacher

    patch instructor_syllabus_topic_path(@first.key), params: { names: { en: "", th: "" } }

    assert_equal I18n.t("flash.topic_name_blank"), flash[:alert]
    assert_empty SyllabusText.where(key: SyllabusText.topic_key(@first.key))
  end

  # Half a rename is worse than none: it pins one language and leaves the other
  # reading off its position, so the next reorder moves the unpinned name while
  # the pinned one stays and the two languages name different lessons.
  test "a rename in one language only is refused, and writes neither" do
    sign_in_as @teacher

    [ { en: "Only English" }, { th: "เฉพาะไทย" }, { en: "One", th: "  " } ].each do |names|
      patch instructor_syllabus_topic_path(@first.key), params: { names: }

      assert_equal I18n.t("flash.topic_name_blank"), flash[:alert]
      assert_empty SyllabusText.where(key: SyllabusText.topic_key(@first.key)),
                   "#{names.keys.join("+")} should have written nothing"
    end
  end

  test "a published course's syllabus changes through the queue, not here" do
    @course.update!(lifecycle_state: "published")
    sign_in_as @teacher

    assert_no_difference "AuditEvent.count" do
      patch instructor_syllabus_move_path(@second.key), params: { direction: "up" }
      patch instructor_syllabus_topic_path(@first.key), params: { names: { en: "x", th: "x" } }
    end

    assert_equal I18n.t("flash.course_not_editable"), flash[:alert]
    assert_equal 2, @second.reload.position
  end

  test "another teacher's syllabus is not theirs to shape" do
    sign_in_as users(:console_instructor)

    assert_no_difference "AuditEvent.count" do
      patch instructor_syllabus_move_path(@second.key), params: { direction: "up" }
      patch instructor_syllabus_topic_path(@first.key), params: { names: { en: "x", th: "x" } }
    end

    assert_equal I18n.t("flash.course_not_yours"), flash[:alert]
    assert_equal 2, @second.reload.position
  end

  test "a student reaches neither route" do
    sign_in_as users(:one)

    patch instructor_syllabus_move_path(@second.key), params: { direction: "up" }
    assert_redirected_to root_path

    patch instructor_syllabus_topic_path(@first.key), params: { names: { en: "x", th: "x" } }
    assert_redirected_to root_path
  end

  test "an administrator teaches nothing and is offered no syllabus tab" do
    sign_in_as users(:admin)
    get instructor_url

    assert_response :success
    assert_select "main nav a", text: /#{I18n.t("instructor.tabs.syllabus")}/, count: 0
  end

  # ---- Adding a lesson: a request, never a write ----------------------------

  test "a teacher asks for a lesson rather than creating one" do
    sign_in_as @teacher

    assert_no_difference "Topic.count" do
      assert_difference "ApprovalRequest.count", 1 do
        post instructor_syllabus_lesson_path, params: lesson_params
      end
    end

    request = ApprovalRequest.newest_first.first
    assert_predicate request, :syllabus_lesson_added?
    assert_predicate request, :pending?
    assert_equal @teacher, request.requester
    assert_not request.approvable_by?(@teacher), "nobody decides their own request"
    assert request.approvable_by?(users(:admin))
  end

  test "an administrator approving it is what creates the lesson" do
    sign_in_as @teacher
    post instructor_syllabus_lesson_path, params: lesson_params
    request = ApprovalRequest.newest_first.first

    assert_difference "Topic.count", 1 do
      request.decide!(actor: users(:admin), outcome: "approved")
    end

    Syllabus.reload!
    topic = Topic.order(:id).last
    assert_equal 1, topic.module_number
    assert_equal "theory", topic.kind
    assert_equal 20, topic.minutes
    I18n.with_locale(:en) { assert_equal "A brand new lesson", Syllabus.topic_name(topic.key, @course.code) }
    I18n.with_locale(:th) { assert_equal "บทเรียนใหม่", Syllabus.topic_name(topic.key, @course.code) }
  end

  test "rejecting it creates nothing" do
    sign_in_as @teacher
    post instructor_syllabus_lesson_path, params: lesson_params
    request = ApprovalRequest.newest_first.first

    assert_no_difference "Topic.count" do
      request.decide!(actor: users(:admin), outcome: "rejected")
    end
    assert_predicate request.reload, :rejected?
  end

  # A key is globally unique and `Topic.key_for` derives one from a position, so
  # a module that has lost a lesson would otherwise mint a key it already used.
  test "a new lesson never takes a key another lesson already has" do
    sign_in_as @teacher
    keys = Topic.pluck(:key)

    3.times do |index|
      post instructor_syllabus_lesson_path, params: lesson_params(en: "Lesson #{index}")
      ApprovalRequest.newest_first.first.decide!(actor: users(:admin), outcome: "approved")
    end

    assert_equal Topic.pluck(:key).uniq, Topic.pluck(:key), "keys must stay unique"
    assert_equal 3, (Topic.pluck(:key) - keys).size
  end

  test "a request that would make an unnamed or impossible lesson is refused" do
    sign_in_as @teacher

    [ lesson_params(en: ""), lesson_params(minutes: 0), lesson_params(module_number: 99),
      lesson_params(topic_kind: "seminar") ].each do |params|
      assert_no_difference "ApprovalRequest.count" do
        post instructor_syllabus_lesson_path, params: params
      end
      assert_equal I18n.t("flash.lesson_request_invalid"), flash[:alert]
    end
  end

  test "asking for a lesson in somebody else's course is refused" do
    sign_in_as users(:console_instructor)

    assert_no_difference "ApprovalRequest.count" do
      post instructor_syllabus_lesson_path, params: lesson_params
    end
    assert_equal I18n.t("flash.course_not_yours"), flash[:alert]
  end

  # A lifecycle request goes stale when the course moves under it. A lesson
  # request is not about the course's state, so it does not.
  test "a lesson request survives the course being published" do
    sign_in_as @teacher
    post instructor_syllabus_lesson_path, params: lesson_params
    request = ApprovalRequest.newest_first.first
    @course.update!(lifecycle_state: "published")

    assert_difference "Topic.count", 1 do
      request.decide!(actor: users(:admin), outcome: "approved")
    end
  end

  # `audit.approval_decided` reads "the %{course} lifecycle request from %{from}
  # to %{to}", and a lesson request has no states for those slots — worse, a nil
  # state resolves through `admin.courses.state.` and interpolated the entire
  # state subtree into the sentence as a hash. A different decision gets a
  # different event.
  test "deciding a lesson request is audited as a lesson, not as a lifecycle move" do
    sign_in_as @teacher
    post instructor_syllabus_lesson_path, params: lesson_params
    ApprovalRequest.newest_first.first.decide!(actor: users(:admin), outcome: "approved")

    event = AuditEvent.newest_first.first
    assert_equal "lesson_addition_decided", event.action
    assert_equal :warn, event.level, "a decision on the queue is worth a second look either way"
    # Stored as written, in the language the decision was read in — the same
    # convention AuditEvent#interpolations applies to a person's name and a
    # card's title, which are not keys and so are not re-localized on read.
    assert_match "บทเรียนใหม่", event.text
    assert_no_match(/lifecycle|วงจร/, event.text)
    assert_no_match(/[{}]/, event.text, "a nil state must not dump the state table into the sentence")
  end

  test "the queue names a lesson request without naming states it has not got" do
    sign_in_as @teacher
    post instructor_syllabus_lesson_path, params: lesson_params
    request = ApprovalRequest.newest_first.first

    I18n.with_locale(:en) do
      assert_match "A brand new lesson", request.title
      assert_match I18n.t("course.kind.theory"), request.meta_text
    end

    sign_in_as users(:admin)
    get admin_url(tab: :queue)

    assert_response :success
    # The console renders in the reader's language, so the Thai name is the one
    # on the screen — which is the point of carrying both in the payload.
    assert_select "main", text: /บทเรียนใหม่/
    assert_select "main", text: /#{I18n.t("course.kind.theory")}/
  end

  private
    def lesson_params(module_number: 1, topic_kind: "theory", minutes: 20,
                      en: "A brand new lesson", th: "บทเรียนใหม่")
      { module_number:, topic_kind:, minutes:, names: { en:, th: } }
    end
end
