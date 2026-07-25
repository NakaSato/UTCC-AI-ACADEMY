class LeaderboardsController < ApplicationController
  def show
    @tab = Leaderboard.tab_for(params[:tab])
    @entries = Leaderboard.entries
  end
end
