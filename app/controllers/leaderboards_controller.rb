class LeaderboardsController < ApplicationController
  def show
    @tab = Leaderboard.tab_for(params[:tab])

    board = Leaderboard.new(Current.user, @tab)
    @entries = board.entries
    @section = board.section
  end
end
