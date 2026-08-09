require "test_helper"

class QualityGateTest < ActiveSupport::TestCase
  test "accessibility and learning-critical failures block release" do
    blocking = Quality::BudgetPolicy::FAILURE_RESPONSE.fetch(:blocking)

    assert_includes blocking, :accessibility
    assert_includes blocking, :authorization
    assert_includes blocking, :academic_integrity
    assert_includes blocking, :learning_critical
  end

  test "lower-risk exceptions require an expiring human-owned waiver" do
    response = Quality::BudgetPolicy::FAILURE_RESPONSE

    assert_includes response.fetch(:warning_with_expiring_waiver), :lower_risk_performance
    assert_equal %i[ owner evidence reason remediation_due expires_at ], response.fetch(:waiver_fields)
  end
end
