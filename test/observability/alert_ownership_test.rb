require "test_helper"

class ObservabilityAlertOwnershipTest < ActiveSupport::TestCase
  test "every actionable signal names an owner and escalation" do
    Observability::SignalCatalog.all.each do |signal|
      assert signal[:owner].present?, "#{signal[:event]} has no owner"
      assert signal[:severity].in?(%w[high critical]), "#{signal[:event]} is not actionable"
      assert signal[:threshold].present?, "#{signal[:event]} has no threshold"
      assert signal[:response_window].present?, "#{signal[:event]} has no response window"
      assert signal[:runbook].present?, "#{signal[:event]} has no runbook"
      assert signal[:escalation].present?, "#{signal[:event]} has no escalation"
      assert signal[:suppression].present?, "#{signal[:event]} has no suppression policy"
    end
  end

  test "the catalog is provider-neutral" do
    contract = Observability::SignalCatalog.all.map(&:values).flatten.join(" ").downcase

    assert_not_includes contract, "datadog"
    assert_not_includes contract, "sentry"
    assert_not_includes contract, "pagerduty"
    assert_not_includes contract, "slack"
  end
end
