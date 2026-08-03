require "test_helper"

class CourseCurriculumTest < ActiveSupport::TestCase
  test "the migrated syllabus belongs to AI1101 and AI1102 has a distinct shape" do
    assert_equal 6, Course.find_by!(code: "AI1101").course_modules.size
    assert_equal 2, Course.find_by!(code: "AI1102").course_modules.size
    assert_equal 15, Syllabus.topic_count("AI1101")
    assert_equal 5, Syllabus.topic_count("AI1102")
    assert_not_equal Syllabus.topic_keys("AI1101"), Syllabus.topic_keys("AI1102")
  end

  test "topic keys remain globally unique and are ordered within each course" do
    assert_equal Topic.pluck(:key).uniq.size, Topic.count
    assert_equal [ "AI1102-1-1", "AI1102-1-2", "AI1102-2-1", "AI1102-2-2", "AI1102-2-3" ],
                 Syllabus.topic_keys("AI1102")
    assert_equal [ "1-1", "1-2", "1-3" ], Syllabus.keys_in(1, "AI1101")
  end

  test "course denominators and bilingual curriculum labels follow the course" do
    ai1101 = CourseCatalog.find("AI1101")
    ai1102 = CourseCatalog.find("AI1102")

    assert_equal 15, ai1101.topics
    assert_equal 5, ai1102.topics

    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        Syllabus.modules(Set.new, "AI1102").each do |mod|
          assert mod.title.present?, "AI1102 module title in #{locale}"
          assert mod.topics.all? { |topic| topic.name.present? }, "AI1102 topic names in #{locale}"
        end
      end
    end
  end

  test "learner progress uses the selected course denominator and next key" do
    key = Syllabus.topic_keys("AI1102").first
    TopicCompletion.record(user: users(:one), course_code: "AI1102", topic_key: key, kind: :learned)

    course = LearnerProgress.new(users(:one)).courses.find { it.code == "AI1102" }

    assert_equal 1, course.learned
    assert_equal 5, course.topics
    assert_equal Syllabus.topic_keys("AI1102").second, course.next_key
  end

  test "AI1102 progress uses only its scoped topic keys" do
    user = users(:two)
    ai1102 = Course.find_by!(code: "AI1102")
    Syllabus.topic_keys("AI1102").first(2).each do |key|
      TopicCompletion.record(user:, course_code: "AI1102", topic_key: key, kind: :learned)
    end

    progress = LearnerProgress.new(user)
    course = progress.courses.find { it.code == "AI1102" }

    assert_equal 2, course.learned
    assert_equal Syllabus.topic_keys("AI1102").third, course.next_key
    assert TopicCompletion.where(user:, course: ai1102).all? { |completion| completion.topic.course == ai1102 }
  end

  test "AI1102 project and certificate requirements use its own syllabus" do
    user = users(:one)
    keys = Syllabus.topic_keys("AI1102")
    project_key = Syllabus.topics("AI1102").find { it.kind == "project" }.key

    TopicCompletion.record(user:, course_code: "AI1102", topic_key: project_key, kind: :applied)
    progress = LearnerProgress.new(user)

    assert_equal 1, progress.projects_done
    assert_equal 1, progress.projects_total
    assert_equal 0, progress.certificates_earned

    (keys - [ project_key ]).each do |key|
      TopicCompletion.record(user:, course_code: "AI1102", topic_key: key, kind: :learned)
    end

    progress = LearnerProgress.new(user)
    assert_equal 1, progress.certificates_earned
  end

  test "completion history remains attributable to its course and topic" do
    user = users(:one)
    first = TopicCompletion.record(user:, course_code: "AI1101", topic_key: "1-1", kind: :learned)
    second = TopicCompletion.record(user:, course_code: "AI1102", topic_key: "AI1102-1-1", kind: :learned)

    assert_equal "AI1101", first.course_code
    assert_equal "1-1", first.topic_key
    assert_equal "AI1102", second.course_code
    assert_equal "AI1102-1-1", second.topic_key
    assert_not_predicate TopicCompletion.record(user:, course_code: "AI1102", topic_key: "1-1", kind: :learned), :persisted?
  end

  test "completion models reject a topic owned by another course" do
    ai1101 = Course.find_by!(code: "AI1101")
    ai1102 = Course.find_by!(code: "AI1102")
    completion = TopicCompletion.new(user: users(:one), course: ai1102,
                                     topic: ai1101.topics.first, learned_at: Time.current)

    assert_not completion.valid?
    assert_predicate completion.errors[:topic], :any?
  end

  test "database and model boundaries enforce curriculum ownership" do
    ai1101 = Course.find_by!(code: "AI1101")
    ai1102 = Course.find_by!(code: "AI1102")
    existing_module = ai1101.course_modules.first
    existing_topic = existing_module.topics.first

    duplicate_module = CourseModule.new(course: ai1101, number: existing_module.number, units: 1)
    assert_not duplicate_module.valid?
    assert_predicate duplicate_module.errors[:number], :any?

    assert ai1102.course_modules.exists?(number: existing_module.number),
           "the same module number is valid in a different course"
    distinct_course_position = CourseModule.new(course: ai1102, number: ai1102.course_modules.maximum(:number) + 1, units: 1)
    assert_predicate distinct_course_position, :valid?

    duplicate_topic = Topic.new(course_module: existing_module, position: existing_topic.position,
                                key: "AI1101-duplicate", kind: "theory", minutes: 1)
    assert_not duplicate_topic.valid?
    assert_predicate duplicate_topic.errors[:position], :any?

    module_index = CourseModule.connection.indexes(:course_modules).find do |index|
      index.columns == %w[ course_id number ]
    end
    assert module_index&.unique

    topic_index = Topic.connection.indexes(:topics).find do |index|
      index.columns == %w[ course_module_id position ]
    end
    assert topic_index&.unique
    assert_includes CourseModule.connection.foreign_keys(:course_modules).map(&:to_table), "courses"
    assert_includes Topic.connection.foreign_keys(:topics).map(&:to_table), "course_modules"
  end

  test "course-owned activity records reject a topic from another course" do
    ai1101 = Course.find_by!(code: "AI1101")
    ai1102 = Course.find_by!(code: "AI1102")
    ai1101_topic = ai1101.topics.first

    submission = Submission.new(user: users(:one), course: ai1102, topic: ai1101_topic,
                                kind: "quiz", answer: "1", passed: false)
    incident = ProctorEvent.new(user: users(:one), course: ai1102, topic: ai1101_topic,
                                kind: "capture", occurred_at: Time.current)

    assert_not submission.valid?
    assert_predicate submission.errors[:topic], :any?
    assert_not incident.valid?
    assert_predicate incident.errors[:topic], :any?
  end
end
