require "test_helper"

# The proctor's report reaching the record. The seam mirrors lesson/submit,
# minus the lock check — the report is evidence against the reporter.
class ProctorIncidentsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "an incident is recorded against the learner, course and topic" do
    assert_difference -> { ProctorEvent.count }, 1 do
      report(kind: "blur")
    end

    assert_response :created
    event = ProctorEvent.sole
    assert_equal users(:one), event.user
    assert_equal "AI1101", event.course.code
    assert_equal "1-1", event.topic.key
    assert_equal 8, event.weight
  end

  test "a kind the proctor does not watch for is refused" do
    assert_no_difference -> { ProctorEvent.count } do
      report(kind: "telepathy")
    end

    assert_response :unprocessable_entity
  end

  test "incidents are accepted only from the exercise and coding task" do
    %w[ theory summary ].each do |step|
      assert_no_difference -> { ProctorEvent.count } do
        report(kind: "blur", step:)
      end
      assert_response :unprocessable_entity
    end

    %w[ exercise code ].each do |step|
      assert_difference -> { ProctorEvent.count }, 1 do
        report(kind: "blur", step:)
      end
      assert_response :created
    end
  end

  test "an unknown course or topic is refused" do
    report(kind: "blur", course: "NOPE")
    assert_response :unprocessable_entity

    report(kind: "blur", topic: "99-9")
    assert_response :unprocessable_entity
    assert_equal 0, ProctorEvent.count
  end

  test "reporting requires a session" do
    sign_out
    report(kind: "blur")

    assert_response :redirect
    assert_equal 0, ProctorEvent.count
  end

  test "the score derives from the kept events and clamps at zero" do
    course = Course.find_by!(code: "AI1101")
    topic = Topic.find_by!(key: "1-1")
    10.times do
      ProctorEvent.create!(user: users(:one), course:, topic:, kind: "capture", occurred_at: Time.current)
    end

    kase = Proctoring.cases.sole
    assert_equal 0, kase.score
    assert_equal :high, kase.severity
  end

  private
    def report(kind:, course: "AI1101", topic: "1-1", step: "exercise")
      post lesson_incident_url, params: { kind:, course:, topic:, step: }, as: :json
    end
end
