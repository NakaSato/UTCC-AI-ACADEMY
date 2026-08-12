require "application_system_test_case"

# Two frames in this app fetch *after* their page has loaded — the leaderboard's
# board and the notification bell answering a broadcast — so both can be refused
# by a gate the page itself already passed. Turbo's own answer to a frame it
# cannot find in a response is to write "Content missing" where the frame was,
# which measured as those two English words landing in the middle of the Thai
# header. Only a browser can see any of this, which is why it is a system test.
class FrameRecoveryTest < ApplicationSystemTestCase
  test "a frame refused by an expired session becomes a page visit, not 'Content missing'" do
    student = users(:one)
    sign_in_through_the_form(student)
    # Wait for the sign-in to land before navigating: `visit` does not queue behind
    # a form submission, and without this the next request goes out cookieless and
    # the test fails on a landing page rather than on what it is about.
    assert_selector "h1", text: I18n.t("catalog.title")

    visit "/progress"
    assert_selector "##{NotificationBell::ID} button"

    # The session dies while the page sits there — what Session::MAX_AGE does at
    # thirty days, and the reason a frame fetch can be refused at all.
    Session.update_all(created_at: (Session::MAX_AGE + 1.day).ago)

    # The fetch is triggered by hand because the thing that triggers it in
    # production cannot reach a browser here: Action Cable's test adapter does not
    # deliver, so a real `broadcast_refresh!` would arrive nowhere. Setting the
    # src is precisely what the pushed frame does on arrival.
    execute_script %(document.getElementById("#{NotificationBell::ID}").src = "#{notifications_bell_path}")

    # The redirect was right, only aimed at the wrong scope — so it is promoted to
    # the navigation it should have been, flash and all.
    assert_current_path root_path
    assert_text I18n.t("flash.sign_in_required")
    assert_no_text "Content missing"
  end
end
