require "test_helper"

# The leaderboard, now that it ranks real learners within a real section. The
# cases that matter are the scoping ones: who a tab ranks you against, and that
# the week tab's cut is a cut of XP, not of streaks.
class LeaderboardTest < ActiveSupport::TestCase
  setup do
    # users(:one) and users(:student) are enrolled in ba_2; users(:two) is not.
    @viewer = users(:one)
  end

  test "rows rank by XP with sequential ranks and a three-row podium" do
    learn(users(:student), 3)
    learn(users(:one), 2)
    learn(users(:two), 1)

    entries = board(:university).entries

    assert_equal (1..3).to_a, entries.map(&:rank)
    assert_equal [ users(:student), users(:one), users(:two) ].map(&:name), entries.map(&:name)
    assert_equal 3, entries.count(&:podium?)
  end

  test "the section tabs rank only the section" do
    learn(users(:one), 1)
    learn(users(:two), 5)

    %i[ week semester ].each do |tab|
      names = board(tab).entries.map(&:name)

      assert_includes names, users(:one).name
      assert_not_includes names, users(:two).name, "#{tab} must not rank a non-member"
    end

    assert_includes board(:university).entries.map(&:name), users(:two).name
  end

  test "exactly one row is you, and it is the viewer's" do
    learn(users(:one), 1)
    learn(users(:student), 2)

    entries = board(:semester).entries

    assert_equal 1, entries.count(&:you?)
    assert_equal users(:one).name, entries.find(&:you?).name
  end

  test "the week tab counts only this week's XP" do
    TopicCompletion.record(user: users(:one), course_code: "AI1101",
                           topic_key: Syllabus.topic_keys.first, kind: :learned, at: 2.weeks.ago)
    TopicCompletion.record(user: users(:one), course_code: "AI1101",
                           topic_key: Syllabus.topic_keys.second, kind: :learned)

    week = board(:week).entries.find(&:you?)
    semester = board(:semester).entries.find(&:you?)

    assert_equal 1, week.topics
    assert_equal 2, semester.topics
    assert_equal LearnerProgress::XP_PER_LEARNED.to_s, week.xp
  end

  test "applying a topic is worth more than learning it alone" do
    TopicCompletion.record(user: users(:one), course_code: "AI1101",
                           topic_key: Syllabus.topic_keys.first, kind: :applied)

    expected = LearnerProgress::XP_PER_LEARNED + LearnerProgress::XP_PER_APPLIED
    assert_equal expected.to_s, board(:week).entries.sole.xp
  end

  test "a learner with nothing in the window does not appear at all" do
    TopicCompletion.record(user: users(:one), course_code: "AI1101",
                           topic_key: Syllabus.topic_keys.first, kind: :learned, at: 3.weeks.ago)

    assert_empty board(:week).entries
    assert_equal 1, board(:semester).entries.size
  end

  test "a viewer in no section is ranked against everyone" do
    learn(users(:two), 1)
    learn(users(:one), 2)

    entries = Leaderboard.new(users(:two), :week).entries

    assert_equal 2, entries.size, "a board of one ranks nobody against nothing"
    assert_predicate entries.find { it.name == users(:two).name }, :you?
  end

  test "selected course limits completions and section membership" do
    TopicCompletion.record(user: users(:one), course_code: "AI1101",
                           topic_key: Syllabus.topic_keys.first, kind: :learned)
    TopicCompletion.record(user: users(:two), course_code: "AI1102",
                           topic_key: Syllabus.topic_keys("AI1102").first, kind: :learned)

    entries = Leaderboard.new(@viewer, :university, course_code: "AI1102").entries

    assert_equal [ users(:two).name ], entries.map(&:name)
    assert_equal LearnerProgress::XP_PER_LEARNED.to_s, entries.first.xp
  end

  test "the streak survives the week cut" do
    # Ten consecutive days ending today: only part is inside this week, but a
    # run of days is a fact about the learner, not about the range.
    Syllabus.topic_keys.first(10).each_with_index do |key, index|
      TopicCompletion.record(user: users(:one), course_code: "AI1101",
                             topic_key: key, kind: :learned, at: (9 - index).days.ago)
    end

    assert_equal 10, board(:week).entries.find(&:you?).streak
  end

  test "xp is delimited and the section is named on the row" do
    learn(users(:one), 9)

    row = board(:semester).entries.sole
    assert_equal "1,080", row.xp
    assert_equal I18n.t("units.section", name: "BA-2"), row.section_text
  end

  test "an unknown tab falls back to the first" do
    assert_equal :week, Leaderboard.tab_for("decade")
    assert_equal :university, Leaderboard.tab_for("university")
  end

  private
    def board(tab) = Leaderboard.new(@viewer, tab)

    def learn(user, count)
      Syllabus.topic_keys.first(count).each do |key|
        TopicCompletion.record(user:, course_code: "AI1101", topic_key: key, kind: :learned)
      end
    end
end
