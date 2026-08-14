require "test_helper"

# A syllabus string keyed on something a reorder cannot move.
#
# The property under test is the one that blocks a builder: `Syllabus.topic_name`
# used to read `course.curricula.<CODE>.modules[i].topics[j]`, so a topic's name
# was its position. Moving a lesson renamed every lesson below it, in both
# languages. Position is the fallback now; `topics.key` is the identity.
class SyllabusTextTest < ActiveSupport::TestCase
  setup do
    @course = courses(:ai1101)
    @topic = topics(:topic_1_1)
    Syllabus.reload!
    SyllabusText.forget
  end

  teardown { Syllabus.reload! }

  test "with no rows every name still comes from the locale files" do
    shipped = I18n.t("course.modules")[0][:topics][0]

    assert_equal shipped, Syllabus.topic_name(@topic.key, @course.code)
    assert_empty SyllabusText.all, "reading must not write"
  end

  test "a row shadows one string in one language" do
    SyllabusText.create!(key: SyllabusText.topic_key(@topic.key), locale: "en", value: "Renamed")
    SyllabusText.forget

    I18n.with_locale(:en) { assert_equal "Renamed", Syllabus.topic_name(@topic.key, @course.code) }

    thai = I18n.with_locale(:th) { I18n.t("course.modules")[0][:topics][0] }
    I18n.with_locale(:th) { assert_equal thai, Syllabus.topic_name(@topic.key, @course.code) }
  end

  # The whole point. Two topics swap places; each keeps the name written against
  # its own key. Under the positional read they would have swapped names.
  test "a reorder moves lessons without moving their names" do
    first, second = topics(:topic_1_1), topics(:topic_1_2)
    SyllabusText.create!(key: SyllabusText.topic_key(first.key), locale: "en", value: "Stays with 1-1")
    SyllabusText.create!(key: SyllabusText.topic_key(second.key), locale: "en", value: "Stays with 1-2")
    SyllabusText.forget

    I18n.with_locale(:en) do
      Topic.transaction do
        second.update!(position: 99)
        first.update!(position: 2)
        second.update!(position: 1)
      end
      Syllabus.reload!

      assert_equal 1, second.reload.position
      assert_equal 2, first.reload.position
      assert_equal "Stays with 1-1", Syllabus.topic_name(first.key, @course.code)
      assert_equal "Stays with 1-2", Syllabus.topic_name(second.key, @course.code)
    end
  end

  test "a module's title and description are overridable the same way" do
    SyllabusText.create!(key: SyllabusText.module_title_key("AI1101", 1), locale: "en", value: "New title")
    SyllabusText.forget

    I18n.with_locale(:en) do
      mod = Syllabus.modules(Set.new, "AI1101").first

      assert_equal "New title", mod.title
      assert_equal I18n.t("course.modules")[0][:desc], mod.desc,
                   "an override on the title must not blank the description"
    end
  end

  # LandingText's rule, and for LandingText's reason: no row may quietly hold a
  # copy of the file it shadows.
  test "writing the default back deletes the row rather than duplicating it" do
    key = SyllabusText.topic_key(@topic.key)
    shipped = I18n.t("course.modules")[0][:topics][0]

    SyllabusText.write(key, "en", "Renamed", default: shipped)
    assert_equal 1, SyllabusText.where(key:).count

    SyllabusText.write(key, "en", shipped, default: shipped)
    assert_empty SyllabusText.where(key:), "a value equal to the default is not a departure from it"

    SyllabusText.write(key, "en", "Renamed", default: shipped)
    SyllabusText.write(key, "en", "  ", default: shipped)
    assert_empty SyllabusText.where(key:), "a blank box means use the default"
  end

  test "a topic with no shipped copy cannot be left nameless" do
    key = SyllabusText.topic_key("AI1101-9-9")

    assert_raises(ActiveRecord::RecordInvalid) { SyllabusText.write(key, "en", "", default: nil) }
    assert_empty SyllabusText.where(key:)
  end

  # A topic somebody added has no position to fall back to, so it answers in
  # whichever language it was written in rather than rendering blank.
  test "a name written in one language answers in the other" do
    key = SyllabusText.topic_key("AI1101-9-9")
    SyllabusText.create!(key:, locale: "th", value: "หัวข้อใหม่")
    SyllabusText.forget

    I18n.with_locale(:en) { assert_equal "หัวข้อใหม่", SyllabusText.any(key) }
  end

  test "a key nothing renders cannot be written" do
    [ "topic..name", "landing.hero.title", "module.AI1101.title", "topic.1-1.name; DROP" ].each do |key|
      assert_not SyllabusText.new(key:, locale: "en", value: "x").valid?, "#{key} should be refused"
    end

    assert SyllabusText.new(key: "topic.AI1102-1-1.name", locale: "en", value: "x").valid?
    assert SyllabusText.new(key: "module.AI1101.2.desc", locale: "en", value: "x").valid?
  end

  test "deleting a key takes every language with it" do
    key = SyllabusText.topic_key(@topic.key)
    %w[ en th ].each { SyllabusText.create!(key:, locale: it, value: "x") }

    SyllabusText.forget_key(key)

    assert_empty SyllabusText.where(key:), "a re-used key must not inherit a dead lesson's name"
  end
end
