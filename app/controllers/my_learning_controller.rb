class MyLearningController < ApplicationController
  def show
    @tab = LearnerProfile.tab_for(params[:tab])
    # Both tabs ship with the page; `tab` only picks which one starts visible.
    @enrollments = LearnerProfile::TABS.index_with { progress.courses_for(it) }
    @open_code = params[:open].presence
    @awards = progress.awards
  end
end
