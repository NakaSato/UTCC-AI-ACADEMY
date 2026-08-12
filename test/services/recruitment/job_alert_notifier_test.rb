require "test_helper"

# The notifier decides whether a student hears about new matches, and how often.
# It shipped with no test at all, so the rule that stops a daily alert firing
# twice in a day — a lock, a re-read of alerts_due?, and a timestamp written
# only when a notification was actually created — was resting on nothing.
class Recruitment::JobAlertNotifierTest < ActiveSupport::TestCase
  setup do
    @student = users(:student)
    @preference = Recruitment::JobDiscoveryPreference.create!(user: @student, alert_frequency: "daily",
                                                              alerts_enabled: true, alert_consent: true)
    @recommendations = [ :a_match, :another_match ]
  end

  def notify = Recruitment::JobAlertNotifier.call(user: @student, recommendations: @recommendations)

  test "notifies a consenting student and records when it did" do
    assert_difference "Notification.count", 1 do
      notify
    end

    assert_not_nil @preference.reload.last_alert_sent_at
  end

  # The whole point of the timestamp: a second pass over the same matches on the
  # same day is silent.
  test "does not send a second daily alert in the same day" do
    notify

    assert_no_difference "Notification.count" do
      notify
    end
  end

  test "sends again once the frequency window has passed" do
    notify
    @preference.update!(last_alert_sent_at: 2.days.ago)

    assert_difference "Notification.count", 1 do
      notify
    end
  end

  test "a weekly subscriber hears nothing on the second day" do
    @preference.update!(alert_frequency: "weekly", last_alert_sent_at: 2.days.ago)

    assert_no_difference "Notification.count" do
      notify
    end
  end

  test "withdrawn consent silences the alert and disables it" do
    @preference.update!(alert_consent: false)

    assert_no_difference "Notification.count" do
      notify
    end

    assert_not @preference.reload.alerts_enabled?
  end

  test "says nothing when there is nothing to recommend" do
    assert_no_difference "Notification.count" do
      Recruitment::JobAlertNotifier.call(user: @student, recommendations: [])
    end

    assert_nil @preference.reload.last_alert_sent_at
  end

  test "says nothing to a student who never set a preference" do
    other = users(:one)

    assert_nil other.job_discovery_preference
    assert_no_difference "Notification.count" do
      Recruitment::JobAlertNotifier.call(user: other, recommendations: @recommendations)
    end
  end

  test "says nothing to an account that is not a student" do
    assert_no_difference "Notification.count" do
      Recruitment::JobAlertNotifier.call(user: users(:admin), recommendations: @recommendations)
    end
  end
end
