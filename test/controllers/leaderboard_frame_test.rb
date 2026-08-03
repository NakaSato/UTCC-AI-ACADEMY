require "test_helper"

# /leaderboard answers twice: the shell a navigation gets, and the board its lazy
# frame comes back for. Both halves are asserted here because neither is visible
# from the other — a shell that quietly folded the rows it was meant to defer
# would look identical on screen, and a board that came back still naming its own
# `src` would fetch itself forever while every frame it drew looked right.
class LeaderboardFrameTest < ActionDispatch::IntegrationTest
  FRAME = "leaderboard-board"

  setup { sign_in_as users(:one) }

  test "the shell ships a lazy frame pointed at this tab and defers the rows" do
    learn(users(:student), 3)

    get leaderboard_url(tab: :semester)

    assert_response :success
    assert_select "turbo-frame##{FRAME}[loading=lazy][src=?]", leaderboard_path(course: "AI1101", tab: :semester)
    assert_select "turbo-frame##{FRAME} [data-in=true]", count: 0
    assert_select "turbo-frame##{FRAME} .sr-only", text: I18n.t("chrome.loading")
    # The one thing the deferral is for: another learner's row is a fold of that
    # learner's completions, and the shell has not paid for it.
    assert_not_includes response.body, users(:student).name
  end

  # A placeholder that is not the height of what replaces it is a layout shift
  # with extra steps, and the height of a board row comes from the line-heights
  # of the two text sizes stacked in its name column. Measured in a browser the
  # mismatch was 65px against 73.375 — 8px of jump per row on arrival. Pixels
  # need a browser, but the coupling that produced them does not: both sides
  # have to name the same two text sizes, so a change to one fails here.
  test "the skeleton's name column stacks the same two text sizes the real row does" do
    learn(users(:one), 1)

    get leaderboard_url
    %w[ .text-14-5 .text-12 ].each { assert_select "turbo-frame##{FRAME} #{it}" }

    get leaderboard_url, headers: frame_headers
    %w[ .text-14-5 .text-12 ].each { assert_select "[data-in=true] #{it}" }
  end

  test "the frame answers with the rows and never with its own source" do
    learn(users(:one), 2)

    get leaderboard_url, headers: frame_headers

    assert_response :success
    assert_select "turbo-frame##{FRAME}" do
      assert_select "[data-in=true]", count: 1
      assert_select "[data-in=true] .truncate", text: users(:one).name
    end
    assert_select "turbo-frame[src]", count: 0
    assert_select "turbo-frame[loading]", count: 0
  end

  # The tabs are links rather than a client-side show/hide, so the tab the URL
  # names is the tab the frame counts. This is what used to be wrong: the switch
  # was intercepted, and picking "semester" left the week's rows on screen.
  test "each tab's frame is that tab's cut of the data" do
    learn(users(:two), 5) # in no section, so only the university tab ranks them

    get leaderboard_url(tab: :semester), headers: frame_headers
    assert_not_includes response.body, users(:two).name

    get leaderboard_url(tab: :university), headers: frame_headers
    assert_select "[data-in=true] .truncate", text: users(:two).name
  end

  test "an empty board says so instead of shipping a bare frame" do
    get leaderboard_url, headers: frame_headers

    assert_select "turbo-frame##{FRAME}", text: /#{I18n.t("leaderboard.empty")}/
    assert_select "[data-in=true]", count: 0
  end

  # The frame is a request like any other. Turbo cannot make it one that skips
  # the gate, and a frame fetched from a page left open past its session has to
  # be refused exactly as the page itself would be.
  test "the frame requires a session" do
    sign_out

    get leaderboard_url, headers: frame_headers

    assert_redirected_to root_path
    assert_equal I18n.t("flash.sign_in_required"), flash[:alert]
  end

  # The minimal frame layout is turbo-rails' own, and it is what keeps the
  # deferred half cheap: the app chrome folds a learner's progress on every
  # screen, so re-rendering it around eight rows would hand back the cost the
  # frame was added to defer.
  test "the frame response carries no app chrome" do
    get leaderboard_url, headers: frame_headers

    assert_response :success
    assert_select "header", count: 0
    assert_select "footer", count: 0
  end

  test "the selected course is preserved by the shell and frame" do
    TopicCompletion.record(user: users(:two), course_code: "AI1102",
                           topic_key: Syllabus.topic_keys("AI1102").first, kind: :learned)

    get leaderboard_url(course: "AI1102", tab: :university)

    assert_response :success
    assert_select "a[href=?]", leaderboard_path(course: "AI1102", tab: :university)
    assert_select "turbo-frame##{FRAME}[src=?]", leaderboard_path(course: "AI1102", tab: :university)

    get leaderboard_url(course: "AI1102", tab: :university), headers: frame_headers

    assert_includes response.body, users(:two).name
  end

  private
    def frame_headers = { "Turbo-Frame" => FRAME }

    def learn(user, count)
      Syllabus.topic_keys.first(count).each do |key|
        TopicCompletion.record(user:, course_code: "AI1101", topic_key: key, kind: :learned)
      end
    end
end
