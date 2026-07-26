class ProgressController < ApplicationController
  def show
    @stats = progress.dashboard_stats
    @activity = progress.activity
    @enrolments = progress.courses_for(:progress)
    @badges = progress.dashboard_badges
  end
end
