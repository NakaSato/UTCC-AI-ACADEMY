module ApplicationHelper
  # A page in one language. Language is a session setting, so without this every
  # translation of a page shares one URL — and a URL that cannot be linked cannot
  # be canonicalised, put in an hreflang pair or listed in a sitemap.
  #
  # The default locale keeps the bare path: `/` is Thai and stays the URL everyone
  # already links to, while English is `/?lang=en`. The param is read for the
  # length of one request and never written to the session — see
  # ApplicationController#requested_locale.
  def locale_url(locale, path: request.path)
    url = "#{request.base_url}#{path}"
    locale.to_sym == I18n.default_locale ? url : "#{url}?lang=#{locale}"
  end

  # Every translation of a page, including the one being rendered — an hreflang
  # set has to name itself or search engines discard the whole cluster.
  def locale_urls(path: request.path)
    I18n.available_locales.index_with { locale_url(it, path:) }
  end

  # Which of the four apps the signed-in account is in. Signed out there is no
  # header to fill, and the learner nav is the harmless default.
  def current_workspace = Current.user&.workspace || :student

  # The dark header's primary nav — one list per workspace, because these are
  # four different jobs and not one job with extra buttons. A nav is a claim
  # about what this app is for, and a recruiter reading "Lesson · Map · Ranking"
  # is being told it is for something they will never do.
  #
  # Every entry is a door its workspace can actually open, matching the
  # `allow_only` on each controller and, for the company entries, the membership
  # scoping inside them.
  #
  # Grouped, because the menu is a list of nine for a learner and an unheaded
  # list of nine is a wall. A group is a claim about what a destination is *for*
  # — learning it, tracking it, or the work beyond the course — and the headings
  # match the footer's, which sorts the same screens the same way.
  def app_nav_groups
    case current_workspace
    in :admin then admin_nav_groups
    in :instructor then instructor_nav_groups
    in :company then company_nav_groups
    else student_nav_groups
    end
  end

  # The flat list behind the groups: what the nav *offers*, regardless of how it
  # is sorted. Every "an entry is a door its workspace can open" check reads
  # this, so grouping cannot quietly add or drop a destination.
  def app_nav_items = app_nav_groups.flat_map { it[:items] }

  # `Course` and `Lesson` are shortcuts into AI1101 — the course a student is
  # currently working through.
  def student_nav_groups
    track = [
      [ t("chrome.nav.my_learning"), my_learning_path ],
      [ t("chrome.nav.progress"),    progress_path ]
    ]
    track << [ t("chrome.nav.ranking"), leaderboard_path ] if FeatureSetting.enabled?(:leaderboard)

    [
      { label: t("chrome.nav_group.learn"), items: [
        [ t("chrome.nav.catalog"), root_path ],
        [ t("chrome.nav.course"),  course_path("AI1101") ],
        [ t("chrome.nav.lesson"),  lesson_path ],
        [ t("chrome.nav.map"),     knowledge_map_path ]
      ] },
      { label: t("chrome.nav_group.track"), items: track },
      # Beyond the coursework, and the reason the group exists: the internship
      # lifecycle starts with a request, so that is the door. A student who has
      # never made one still needs to learn the feature exists, which is why it
      # is unconditional — for two increments it was reachable only by URL.
      { label: t("chrome.nav_group.beyond"), items: [
        [ t("chrome.nav.internships"), internship_requests_path ],
        [ t("chrome.nav.writing"),     academic_posts_path ]
      ] }
    ]
  end

  # Admin first — it is the admin's index. Organizations because creating one
  # and granting its first membership are admin-only actions.
  #
  # No Teaching entry: /instructor is a report on a section an admin does not
  # teach, so for them it is somebody else's screen. An admin who genuinely
  # teaches holds the instructor role and gets that workspace; the route still
  # admits any staff member who types it.
  def admin_nav_groups
    [
      { label: t("chrome.nav_group.administration"), items: [
        [ t("chrome.nav.admin"),         admin_path ],
        [ t("chrome.nav.organizations"), companies_path ]
      ] },
      # An administrator assigns every internship's university supervisor, and
      # supervises and hosts none of them — so without this entry the screen
      # that grants supervision has no door for the only role that may use it.
      { label: t("chrome.nav_group.university"), items: [
        [ t("chrome.nav.internships"), internship_placements_path ]
      ] }
    ]
  end

  # Short on purpose: this is everything an instructor has that a learner does
  # not. Padding it with the catalog and the knowledge map would be padding it
  # with screens about somebody else's coursework.
  def instructor_nav_groups
    [
      { label: t("chrome.nav_group.teaching"), items: [
        [ t("chrome.nav.instructor"), instructor_path ]
      ] },
      # The internships this account supervises for the university. Offered to
      # every staff member rather than only the assigned, for the same reason
      # the student's entry is: a screen nobody is told about is a screen
      # nobody opens. It lists assignments only, so an unassigned instructor
      # sees an empty one. SPEC-0041 increment 3.
      { label: t("chrome.nav_group.university"), items: [
        [ t("chrome.nav.internships"), internship_placements_path ],
        [ t("chrome.nav.writing"),     academic_posts_path ]
      ] }
    ]
  end

  # A company member's four: what is waiting on them, the companies they belong
  # to, the case work they run, and the students they have placed. None of it is
  # coursework.
  #
  # Work points at `/` rather than at a slug, because a member of two companies
  # has no single work surface — `/` sends one of them to their board and the
  # other to the chooser, which is the same answer the redirect already gives.
  def company_nav_groups
    [
      { label: t("chrome.nav_group.company"), items: [
        [ t("chrome.nav.work"),          root_path ],
        [ t("chrome.nav.organizations"), companies_path ]
      ] },
      { label: t("chrome.nav_group.students"), items: [
        [ t("chrome.nav.business_cases"), business_cases_path ],
        [ t("chrome.nav.placements"),     internship_placements_path ]
      ] }
    ]
  end

  # Every link inside a lesson has to carry which lesson it is. A bare
  # `lesson_path(step:)` resolves to whatever topic the learner is next on, so
  # stepping through a topic they went back to would silently jump forward.
  def lesson_step_path(step)
    lesson_path(course: @course.code, topic: @topic_key, step:)
  end

  # A nav item is current when the request is on its path — matching on path
  # only, so query strings (filters, tabs, steps) do not deselect it.
  def nav_current?(path)
    request.path == path.split("?").first
  end

  # Up to two initials for the avatar plate. Thai names are usually two words,
  # so the same rule reads correctly in both languages.
  def user_initials(user)
    user&.name.to_s.split.first(2).map { |part| part.first }.join.presence || "?"
  end

  def app_user_menu
    [
      [ t("chrome.menu.profile"),    profile_path ],
      [ t("chrome.menu.transcript"), progress_path ],
      [ t("chrome.menu.settings"),   my_learning_path ],
      [ t("chrome.menu.help"),       root_path ]
    ]
  end

  # ---- Landing page (signed out) ----------------------------------------
  # Anchors point at landing-page sections until real pages/models exist. The
  # key doubles as the section id the header's scroll spy watches, so the nav
  # and the page stay in step from one list.
  def nav_links
    %i[learn tracks community events faq].to_h do |section|
      [ t("landing.nav.#{section}"), contributors_page? ? root_path(anchor: section) : "##{section}" ]
    end
  end

  def contributors_page?
    request.path == contributors_path
  end

  # The footer's link columns. Ruby holds only the shape — which columns
  # exist, in what order, and where each link goes; every label is looked up as
  # `chrome.footer.columns.<column>.title` / `.links.<link>`. Keyed rather than
  # positional, so adding a link here without its copy raises a missing
  # translation instead of silently shifting the labels below it.
  #
  # The footer is shared chrome, but its first two columns are not: signed out
  # they are anchors into the landing page's sections, and signed in that page
  # is not on screen, so `#learn` would scroll nowhere. The signed-in variant
  # points at the app's own screens instead. The university column — three
  # external sites — is the same either way.
  def footer_columns
    (authenticated? ? app_footer_columns : (contributors_page? ? contributors_footer_columns : landing_footer_columns)).merge(university_footer_column)
  end

  def contributors_footer_columns
    {
      profile: {
        story: "#story",
        people: "#contributors",
        practice: "#practice"
      },
      join: {
        academy: root_path,
        sign_up: register_path
      }
    }
  end

  def landing_footer_columns
    {
      start: {
        what_is_ai: "#learn",
        tracks: "#tracks",
        faq: "#faq"
      },
      community: {
        showcase: "#community",
        share: "#community",
        events: "#events",
        contributors: contributors_path,
        proposal: new_proposal_request_path
      }
    }
  end

  def app_footer_columns
    columns = {
      learn: {
        catalog: root_path,
        course: course_path("AI1101"),
        map: knowledge_map_path
      },
      track: {
        my_learning: my_learning_path,
        progress: progress_path
      }
    }
    columns[:track][:ranking] = leaderboard_path if FeatureSetting.enabled?(:leaderboard)
    columns
  end

  def university_footer_column
    {
      university: {
        engineering: "https://eng.utcc.ac.th",
        utcc: "https://utcc.ac.th",
        admissions: "https://admissions.utcc.ac.th/loginUTCC"
      }
    }
  end
end
