class HomeController < ApplicationController
  # The landing page is the app's front door — readable without an account.
  allow_unauthenticated_access only: :index

  # `/` is two pages: the catalog for a signed-in student, the public landing
  # page for everyone else. An admin's home is the admin screen instead, so the
  # front door — the logo, the first nav item, a bare `/` — lands them there.
  def index
    return redirect_to admin_path if authenticated? && Current.user.admin?

    # Signed out this falls through to `home/index`, the landing page — whose view
    # reads `Landing` directly and so needs no assigns, the same way the header
    # reads `LearnerProfile`.
    render_catalog if authenticated?
  end

  private
    def render_catalog
      @filter = filter_param
      # The learner's own counts, so a card's progress bar is their progress.
      @courses = progress.courses.select { |course| course.tagged?(@filter) }
      @filter_counts = CourseCatalog.filter_counts

      render :catalog
    end

    def filter_param
      requested = params[:filter].to_s.to_sym
      CourseCatalog::FILTERS.include?(requested) ? requested : :all
    end
end
