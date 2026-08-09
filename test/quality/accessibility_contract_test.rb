require "test_helper"

class AccessibilityContractTest < ActiveSupport::TestCase
  test "the approved accessibility contract names the checks automation cannot replace" do
    assert_equal "WCAG 2.2 AA", Quality::BudgetPolicy::ACCESSIBILITY_TARGET

    expected = %i[
      keyboard
      focus
      screen_reader
      text_scaling
      contrast
      reduced_motion
      bilingual
      learning_critical
    ]

    assert_equal expected, Quality::BudgetPolicy::ACCESSIBILITY_CHECKS
  end

  test "every supported environment covers both application locales" do
    Quality::BudgetPolicy::SUPPORTED_MATRIX.each do |environment|
      assert_equal %w[ en th ], environment.fetch(:locales)
    end
  end
end
