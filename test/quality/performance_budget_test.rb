require "test_helper"

class PerformanceBudgetTest < ActiveSupport::TestCase
  test "user-facing latency and transfer budgets are explicit" do
    budgets = Quality::BudgetPolicy::PERFORMANCE_BUDGETS

    assert_equal 2_000, budgets.fetch(:initial_interaction_p75_ms)
    assert_equal 4_000, budgets.fetch(:initial_interaction_p95_ms)
    assert_equal 1_500_000, budgets.fetch(:initial_transfer_p75_bytes)
    assert_equal 3_000_000, budgets.fetch(:initial_transfer_p95_bytes)
    assert_operator budgets.fetch(:initial_interaction_p95_ms), :>, budgets.fetch(:initial_interaction_p75_ms)
    assert_operator budgets.fetch(:initial_transfer_p95_bytes), :>, budgets.fetch(:initial_transfer_p75_bytes)
  end

  test "query growth uses the existing constant-cost evidence" do
    growth = Quality::BudgetPolicy::QUERY_GROWTH

    assert_equal "constant_cost", growth.fetch(:rule)
    assert_equal %i[ empty typical growth ], growth.fetch(:fixture_states)
    assert Rails.root.join(growth.fetch(:baseline).split("#").first).file?
    assert Rails.root.join(growth.fetch(:existing_enforcement)).file?
  end
end
