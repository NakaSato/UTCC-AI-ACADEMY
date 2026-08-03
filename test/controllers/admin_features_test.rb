require "test_helper"

class AdminFeaturesTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "the Features tab renders only approved persisted settings" do
    get admin_url(tab: :features)

    assert_response :success
    %w[search notifications leaderboard].each do |key|
      assert_select "form[action=?]", admin_feature_setting_path(key), count: 1
    end
    %w[learning_map catalog_cols gamify hearts lives_cap proctoring language].each do |key|
      assert_select "form[action=?]", admin_feature_setting_path(key), count: 0
    end
    assert_select "button[role=switch][aria-label=?]", I18n.t("admin.features.keys.leaderboard"), count: 1
  end

  test "an admin toggles a setting and writes one audited change" do
    setting = FeatureSetting.find_by!(key: "leaderboard")

    patch admin_feature_setting_path("leaderboard"),
          params: { enabled: true, lock_version: setting.lock_version }

    assert_redirected_to admin_path(tab: :features)
    assert setting.reload.enabled
    assert_equal({ "key" => "leaderboard", "from_state" => "off", "to_state" => "on" }, AuditEvent.sole.params)
    assert_equal "feature_setting_changed", AuditEvent.sole.action
    assert_equal :warn, AuditEvent.sole.level
  end

  test "a stale setting update changes neither setting nor audit log" do
    setting = FeatureSetting.find_by!(key: "leaderboard")
    setting.update!(enabled: true)

    patch admin_feature_setting_path("leaderboard"),
          params: { enabled: false, lock_version: 0 }

    assert_redirected_to admin_path(tab: :features)
    assert_equal I18n.t("flash.feature_setting_stale"), flash[:alert]
    assert setting.reload.enabled
    assert_empty AuditEvent.all
  end

  test "invalid settings and unauthorized updates do nothing" do
    patch admin_feature_setting_path("proctoring"), params: { enabled: true, lock_version: 0 }

    assert_redirected_to admin_path(tab: :features)
    assert_empty AuditEvent.all

    sign_in_as users(:student)
    patch admin_feature_setting_path("leaderboard"), params: { enabled: true, lock_version: 0 }

    assert_redirected_to root_path
    assert_not FeatureSetting.find_by!(key: "leaderboard").enabled
    assert_empty AuditEvent.all
  end

  test "turning search off hides and ignores the existing admin search controls" do
    FeatureSetting.find_by!(key: "search").update!(enabled: false)

    get admin_url(tab: :courses, q: "AI1101")

    assert_response :success
    assert_not_includes response.body, I18n.t("admin.courses_search_ph")
    assert_includes response.body, "AI1102"
  end

  test "the disabled leaderboard redirects direct access and hides the learner nav" do
    get leaderboard_path

    assert_redirected_to root_path
    assert_equal I18n.t("flash.feature_unavailable"), flash[:alert]

    get root_path
    assert_select "header a[href=?]", leaderboard_path, count: 0
  end
end
