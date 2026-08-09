class HomeController < ApplicationController
  # The landing page is the app's front door — readable without an account.
  allow_unauthenticated_access only: :index

  # `/` is the front door for four different apps and a landing page for
  # everyone else. The logo, the first nav item and a bare `/` all arrive here,
  # so each workspace is sent to its own home rather than to a catalog of
  # courses three of the four are not taking.
  #
  # A company member is sent to their organizations because that is the best
  # screen that exists today, not because it is a dashboard — see SPEC-0044.
  def index
    # Signed out this falls through to `home/index`, the landing page — whose
    # view reads `Landing` directly and so needs no assigns, the same way the
    # header reads `Landing` too.
    return unless authenticated?

    case Current.user.workspace
    in :admin then redirect_to admin_path
    in :instructor then redirect_to instructor_path
    in :company then redirect_to company_home
    else render_catalog
    end
  end

  private
    # Most company members belong to one organization, and for them the front
    # door is that company's profile — /northstar, the page about them. The list
    # is only worth showing to someone who has to choose.
    def company_home
      organizations = Current.user.organizations.merge(Organization.active)

      organizations.one? ? company_path(organizations.first) : recruitment_organizations_path
    end
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
