class HomeController < ApplicationController
  # The landing page is the app's front door — readable without an account.
  allow_unauthenticated_access only: :index

  # `/` is the front door for four different apps and a landing page for
  # everyone else. The logo, the first nav item and a bare `/` all arrive here,
  # so each workspace is sent to its own home rather than to a catalog of
  # courses three of the four are not taking.
  #
  # A company member is sent to their company's work surface — the slice
  # SPEC-0044 deferred and ADR-0048 accepted. Everyone else's landing is
  # unchanged.
  def index
    # Signed out this falls through to `home/index`, the landing page — whose
    # view reads `Landing` directly and so needs no assigns, the same way the
    # header reads `Landing` too.
    return unless authenticated?

    case Current.user.workspace
    in :admin then redirect_to admin_path
    in :instructor then redirect_to instructor_path
    in :company then redirect_to company_home_path(Current.user)
    else render_catalog
    end
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
