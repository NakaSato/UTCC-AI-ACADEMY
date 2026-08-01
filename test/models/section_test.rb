require "test_helper"

class SectionTest < ActiveSupport::TestCase
  test "the label names the course and the section" do
    assert_equal "AI1101 · BA-2", sections(:ba_2).label
  end

  # The column stores the Buddhist form the registrar writes; only the English
  # rendering converts. Storage carries no locale.
  test "the term converts to the Gregorian year for English readers only" do
    section = sections(:ba_2)

    I18n.with_locale(:th) { assert_equal "1/2569", section.term_text }
    I18n.with_locale(:en) { assert_equal "1/2026", section.term_text }
  end

  # A term someone typed in Gregorian already must not be shifted back to 1483.
  test "a term already below the offset is left alone" do
    section = Section.new(term: "1/2026")

    I18n.with_locale(:en) { assert_equal "1/2026", section.term_text }
  end

  test "for_staff returns a section the instructor teaches" do
    assert_equal sections(:ba_2), Section.for_staff(users(:instructor))
  end

  test "for_staff does not expose another instructor's section" do
    unassigned = User.create!(name: "Unassigned Instructor", student_id: "2011071730993",
                              password: "securePass1", role: :instructor)

    assert_nil Section.for_staff(unassigned)
  end

  test "for_staff permits an admin to inspect any section" do
    assert_equal sections(:ba_2), Section.for_staff(users(:admin)),
                 "admins retain institution-wide access"
  end

  test "a duplicate code in the same course and term is rejected" do
    dupe = Section.new(course: sections(:ba_2).course, term: "1/2569", code: "BA-2")

    assert_not_predicate dupe, :valid?
  end
end
