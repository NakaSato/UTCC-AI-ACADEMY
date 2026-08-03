require "test_helper"

# The catalog taxonomy exists in three places that must agree — the migration
# that writes it, db/seeds.rb that restores it after a replant, and the fixtures
# the suite runs against. Nothing makes them agree automatically, so this asserts
# the shape every screen depends on. A row added to one copy and not the others
# shows up here rather than as a syllabus that is quietly one topic short.
#
# It is the same job placeholder_content_test.rb does for the positional locale
# joins, which are still positional: `course.modules[i]` lines up with the module
# numbered i + 1, and its `topics[j]` with the topic at position j + 1.
class TaxonomyTest < ActiveSupport::TestCase
  test "the catalog has eight courses, in position order, each with a unique code" do
    codes = CourseCatalog.codes

    assert_equal 8, codes.size
    assert_equal codes.uniq, codes
    assert_equal (1..8).to_a, Course.in_catalog_order.map(&:position)
    assert_equal "AI1101", codes.first, "the default course leads the catalog"
  end

  test "the syllabus is six modules and fifteen topics, seven of them applied" do
    assert_equal 6, Syllabus.entries.size
    assert_equal 15, Syllabus.topic_count
    assert_equal 7, Syllabus.applied_topic_count
  end

  test "every topic key is <module>-<position> and resolves back to its row" do
    Syllabus.entries.each do |course_module|
      course_module.topics.each_with_index do |topic, index|
        assert_equal index + 1, topic.position, "topics are positioned from one, in order"
        assert_equal "#{course_module.number}-#{topic.position}", topic.key
        assert_equal topic, Syllabus.topic(topic.key)
      end
    end
  end

  test "topic keys are in syllabus order, which is what next_topic_key walks" do
    assert_equal Topic.in_syllabus_order.map(&:key), Syllabus.topic_keys
    assert_equal Syllabus.topic_keys.first, Syllabus.next_topic_key(Set.new)
    assert_nil Syllabus.next_topic_key(Syllabus.topic_keys.to_set)
  end

  # The counts under a progress bar and on a stat tile are the same number by
  # construction. This is invariant 7 in CLAUDE.md.
  test "each course reports its own syllabus as its denominator" do
    CourseCatalog.all.each do |course|
      assert_equal Syllabus.topic_count(course.code), course.topics, course.code
      assert_equal Syllabus.applied_topic_count(course.code), course.applied_topics, course.code
    end

    assert_equal 15, CourseCatalog.find("AI1101").topics
    assert_equal 5, CourseCatalog.find("AI1102").topics
  end

  test "tags come back as symbols, so the catalog filters match" do
    course = Course.find_by!(code: "AI1101")

    assert_equal %i[ core popular ], course.tags
    assert CourseCatalog.all.find { it.code == "AI1101" }.tagged?(:core)
  end

  # Every course code and topic key still has copy behind it in both locales —
  # the join is by code for a course and by position for a topic.
  test "every course and topic has copy in both locales" do
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        CourseCatalog.all.each do |course|
          assert course.title.present?, "#{course.code} title in #{locale}"
          assert course.description.present?, "#{course.code} desc in #{locale}"
        end

        Syllabus.topic_keys.each do |key|
          assert Syllabus.topic_name(key).present?, "topic #{key} name in #{locale}"
        end
      end
    end
  end
end
