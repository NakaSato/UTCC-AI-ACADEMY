class ThemesController < ApplicationController
  # The toggle sits in the header of every screen, including the auth ones —
  # the same reach as the language toggle it stands beside.
  allow_unauthenticated_access

  # POST for the same reason the language toggle is: Turbo prefetches links on
  # hover, and a GET would repaint the app just by pointing at the button.
  #
  # "system" is stored as no preference at all rather than as a third value, so
  # a visitor who picks it goes back to being answered by the media query — the
  # same shape as a locale that falls through to Accept-Language.
  def update
    if params[:theme] == "system"
      session.delete(:theme)
    else
      session[:theme] = params[:theme]
    end

    redirect_back fallback_location: root_path
  end
end
