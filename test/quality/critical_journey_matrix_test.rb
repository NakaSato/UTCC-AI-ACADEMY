require "test_helper"

class CriticalJourneyMatrixTest < ActiveSupport::TestCase
  REQUIRED_JOURNEYS = %i[
    authentication
    catalog_course_lesson
    progress_map
    leaderboard
    instructor_admin
    academic_reader_editor
    syllabus_pdf
    notification_frame
  ].freeze

  test "the quality matrix covers every approved critical journey" do
    journeys = Quality::BudgetPolicy::CRITICAL_JOURNEYS
    keys = journeys.map { |journey| journey.fetch(:key) }

    assert_equal REQUIRED_JOURNEYS, keys

    journeys.each do |journey|
      assert journey.fetch(:paths).any?, "#{journey[:key]} needs at least one route"
      assert_equal %i[ empty typical growth ], journey.fetch(:data_states)
      assert_predicate journey.fetch(:owner), :present?
    end
  end

  test "the matrix is bilingual and includes a named environment" do
    assert_equal %w[ en th ], Quality::BudgetPolicy::LOCALES

    Quality::BudgetPolicy::SUPPORTED_MATRIX.each do |environment|
      assert_predicate environment.fetch(:name), :present?
      assert_predicate environment.fetch(:browsers), :any?
      assert_equal %w[ en th ], environment.fetch(:locales)
      assert_predicate environment.fetch(:network), :present?
    end
  end
end
