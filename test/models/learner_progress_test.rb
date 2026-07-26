require "test_helper"

# The reading half: every figure the progress screens show, counted off rows.
class LearnerProgressTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @keys = Syllabus.topic_keys
  end

  # Completions spread over the last `days_ago` list, oldest first.
  def complete(count = 1, course: "AI1101", kind: :learned, days_ago: nil, from: 0)
    count.times do |index|
      at = days_ago ? days_ago[index].days.ago : Time.current
      TopicCompletion.record(user: @user, course_code: course, topic_key: @keys[from + index], kind:, at:)
    end
    LearnerProgress.new(@user.reload)
  end

  test "a learner with no rows reports zero rather than dividing by it" do
    progress = LearnerProgress.new(@user)

    assert_equal 0, progress.learned
    assert_equal 0, progress.learned_percent
    assert_equal 0, progress.applied_percent
    assert_equal 0, progress.streak
    assert_equal 0, progress.xp
    assert_equal 1, progress.level
    assert_empty progress.started_courses
    assert_nil progress.rank
  end

  test "totals count only the courses actually started" do
    progress = complete(3)

    assert_equal 3, progress.learned
    assert_equal CourseCatalog.find("AI1101").topics, progress.learned_total
    assert_equal [ "AI1101" ], progress.started_courses.map(&:code)
  end

  test "learning and applying are counted apart" do
    complete(3)
    progress = complete(1, kind: :applied)

    assert_equal 3, progress.learned, "applying a topic already learned adds no second row"
    assert_equal 1, progress.applied
  end

  test "xp and level follow the completions" do
    progress = complete(3)
    assert_equal 3 * LearnerProgress::XP_PER_LEARNED, progress.xp

    progress = complete(1, kind: :applied)
    assert_equal 3 * LearnerProgress::XP_PER_LEARNED + LearnerProgress::XP_PER_APPLIED, progress.xp
    assert_equal progress.xp / LearnerProgress::XP_PER_LEVEL + 1, progress.level
    assert_equal progress.level * LearnerProgress::XP_PER_LEVEL, progress.xp_target
    assert_operator progress.xp_percent, :<=, 100
  end

  test "gems match what the lesson hands out in the browser" do
    progress = complete(2)
    assert_equal 2 * LearnerProgress::GEMS_PER_LEARNED, progress.gems
  end

  test "a streak counts back from today and stops at the first gap" do
    progress = complete(3, days_ago: [ 0, 1, 2 ])
    assert_equal 3, progress.streak

    # A fourth day, but with day 3 missing, does not extend the run.
    progress = complete(1, days_ago: [ 4 ], from: 3)
    assert_equal 3, progress.streak
  end

  test "yesterday still heads a streak but the day before does not" do
    assert_equal 1, complete(1, days_ago: [ 1 ]).streak

    @user.topic_completions.destroy_all
    assert_equal 0, complete(1, days_ago: [ 2 ]).streak
  end

  test "the contribution grid ends on today and stays in range" do
    progress = complete(2, days_ago: [ 0, 5 ])
    grid = progress.activity

    assert_equal LearnerProgress::ACTIVITY_DAYS, grid.size
    assert grid.all? { (0..LearnerProgress::HOTTEST).cover?(it) }
    assert_equal 1, grid.last, "the last square is today"
    assert_equal 1, grid[-6]
    assert_equal 0, grid[-2]
  end

  test "a course is in progress until every topic is done, then completed" do
    progress = complete(2)

    assert_equal [ "AI1101" ], progress.courses_for(:progress).map(&:code)
    assert_empty progress.courses_for(:done)

    course = progress.courses_for(:progress).first
    assert_predicate course, :in_progress?
    assert_equal I18n.t("my_learning.badge_state.now"), course.badge
  end

  test "next up is the first topic not finished" do
    progress = complete(2)
    course = progress.courses_for(:progress).first

    assert_equal @keys[2], course.next_key
    assert_equal I18n.t("progress.next_up", topic: Syllabus.topic_name(@keys[2])), course.next_up
  end

  test "hours studied come from the minutes the syllabus budgets" do
    progress = complete(2)
    minutes = @keys.first(2).sum { Syllabus.topic_minutes(it) }

    assert_equal (minutes / 60.0).round(1), progress.hours_studied
  end

  test "the dashboard stats report counts, and say so when a week is empty" do
    progress = complete(1, days_ago: [ 30 ])
    stats = progress.dashboard_stats

    assert_equal "1", stats[0][:value]
    assert_equal I18n.t("progress.delta.none"), stats[0][:delta]
    # Projects are not recorded anywhere, so that tile is still written copy.
    assert_equal I18n.t("progress.stats")[2][:value], stats[2][:value]
  end

  test "rank orders students by xp and leaves an idle learner unranked" do
    complete(3)
    TopicCompletion.record(user: users(:two), course_code: "AI1101", topic_key: @keys.first, kind: :learned)

    assert_equal 1, LearnerProgress.new(@user.reload).rank
    assert_equal 2, LearnerProgress.new(users(:two)).rank
    assert_nil LearnerProgress.new(users(:student)).rank
  end
end
