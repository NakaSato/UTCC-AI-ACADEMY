# Two responses from one URL, told apart by the Turbo-Frame header.
#
# A navigation gets the shell — heading, subtitle, tabs and the column header —
# and the board arrives in the lazy frame that shell renders. The split is the
# whole point: `entries` folds every contender's completions, which on the
# university tab is the entire topic_completions table, and that is the one
# figure on the screen nobody is reading in the first 200ms.
class LeaderboardsController < ApplicationController
  def show
    @tab = Leaderboard.tab_for(params[:tab])
    @course = Course.find_by(code: params[:course].presence || Syllabus::DEFAULT_COURSE) ||
              Course.find_by!(code: Syllabus::DEFAULT_COURSE)
    @courses = CourseCatalog.all
    @course_card = @courses.find { it.code == @course.code }
    board = Leaderboard.new(Current.user, @tab, course_code: @course.code)

    if turbo_frame_request?
      @entries = board.entries
      render "board"
    else
      # The subtitle names the viewer's own section whatever the tab, so the
      # shell asks for that and nothing else — no completion is read.
      @section = board.section
    end
  end
end
