require "test_helper"
require_relative "recovery_test_helper"

class RecoveryRestoreIsolationTest < ActiveSupport::TestCase
  include RecoveryTestHelpers

  test "the restore target must disable production writes and outbound side effects" do
    unsafe = isolated_target.merge(production_writes_disabled: false)

    payload = capture_signal("recovery.restore.failure") do
      assert_raises(Recovery::Isolation::UnsafeTarget) { Recovery::Isolation.validate!(unsafe) }
    end

    assert_equal "unsafe_target", payload.fetch(:fields).fetch("reason")
  end

  test "the approved target requires isolated websockets, non-production credentials, and immutable source" do
    assert_equal isolated_target.transform_keys(&:to_s), Recovery::Isolation.validate!(isolated_target)
  end

  test "a restore cannot proceed when outbound notifications remain enabled" do
    unsafe = isolated_target.merge(notifications_disabled: false, outbound_mail_disabled: false)

    assert_raises(Recovery::Isolation::UnsafeTarget) { Recovery::Isolation.validate!(unsafe) }
  end

  test "a missing target is unsafe rather than an incidental type error" do
    assert_raises(Recovery::Isolation::UnsafeTarget) { Recovery::Isolation.validate!(nil) }
  end
end
