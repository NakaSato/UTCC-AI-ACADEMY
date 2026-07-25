class LanguagesController < ApplicationController
  # The toggle sits in the header of every screen, including the auth ones.
  allow_unauthenticated_access

  def update
    session[:locale] = params[:locale]
    redirect_back fallback_location: root_path
  end
end
