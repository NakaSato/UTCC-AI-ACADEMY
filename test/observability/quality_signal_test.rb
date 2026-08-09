require "test_helper"

class QualitySignalTest < ActiveSupport::TestCase
  test "quality telemetry uses safe dimensions and correlation context" do
    observability = Quality::BudgetPolicy::OBSERVABILITY

    assert_includes observability.fetch(:dimensions), :route
    assert_includes observability.fetch(:dimensions), :locale
    assert_includes observability.fetch(:dimensions), :release
    assert_includes observability.fetch(:required_context), :request_id
    assert_includes observability.fetch(:required_context), :environment
  end

  test "quality telemetry excludes learner and credential content" do
    forbidden = Quality::BudgetPolicy::OBSERVABILITY.fetch(:forbidden_fields)

    %i[ learner_answers credentials cookies reset_links direct_identifiers ].each do |field|
      assert_includes forbidden, field
    end
  end
end
