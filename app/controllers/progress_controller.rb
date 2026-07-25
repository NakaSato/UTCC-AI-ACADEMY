class ProgressController < ApplicationController
  def show
    @stats = LearnerProfile.dashboard_stats
    @activity = LearnerProfile.activity
    @enrolments = LearnerProfile.enrolments
    @badges = LearnerProfile.dashboard_badges
  end
end
