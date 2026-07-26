class MyLearningController < ApplicationController
  # The two tabs. Both ship with the page; `tab` only picks which starts
  # visible. The whitelist lived in LearnerProfile until that module emptied.
  TABS = %i[ progress done ].freeze

  def show
    @tab = TABS.include?(params[:tab].to_s.to_sym) ? params[:tab].to_s.to_sym : TABS.first
    @enrollments = TABS.index_with { progress.courses_for(it) }
    @open_code = params[:open].presence
    @awards = progress.awards
  end
end
