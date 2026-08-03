require "test_helper"

class FeatureSettingTest < ActiveSupport::TestCase
  test "the allow-list exposes safe defaults and stored values" do
    assert_equal [ "notifications", "search", "leaderboard" ], FeatureSetting::KEYS
    assert FeatureSetting.enabled?(:notifications)
    assert FeatureSetting.enabled?(:search)
    assert_not FeatureSetting.enabled?(:leaderboard)

    FeatureSetting.find_by!(key: "leaderboard").update!(enabled: true)

    assert FeatureSetting.enabled?(:leaderboard)
  end

  test "a missing row falls back to its approved default" do
    FeatureSetting.find_by!(key: "notifications").destroy!

    assert FeatureSetting.enabled?(:notifications)
  end

  test "updates are typed and use optimistic locking" do
    setting = FeatureSetting.find_by!(key: "leaderboard")

    FeatureSetting.update!(key: "leaderboard", enabled: true, expected_lock_version: setting.lock_version)

    assert setting.reload.enabled
    assert_equal 1, setting.lock_version
    assert_raises(ActiveRecord::StaleObjectError) do
      FeatureSetting.update!(key: "leaderboard", enabled: false, expected_lock_version: 0)
    end
    assert setting.reload.enabled
  end

  test "unknown keys and malformed booleans are rejected" do
    assert_nil FeatureSetting.parse_boolean("yes")
    assert_raises(ActiveRecord::RecordInvalid) do
      FeatureSetting.update!(key: "proctoring", enabled: true, expected_lock_version: 0)
    end
  end
end
