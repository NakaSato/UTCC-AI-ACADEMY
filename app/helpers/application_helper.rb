module ApplicationHelper
  # The dark header's primary nav. `Course` and `Lesson` are shortcuts into
  # AI1101 — the course a student is currently working through.
  #
  # The instructor and admin entries are role-gated, matching the `allow_only`
  # on each controller: a student is never shown a door they cannot open. Both
  # the desktop nav and the burger drawer read this one list.
  #
  # An admin gets a nav of its own rather than the learning nav with two extra
  # entries: `/` only redirects them back to /admin, so the catalog, the course
  # shortcuts and the learner screens are not part of their app.
  def app_nav_items
    return admin_nav_items if Current.user&.admin?

    items = [
      [ t("chrome.nav.catalog"),     root_path ],
      [ t("chrome.nav.my_learning"), my_learning_path ],
      [ t("chrome.nav.course"),      course_path("AI1101") ],
      [ t("chrome.nav.lesson"),      lesson_path ],
      [ t("chrome.nav.map"),         knowledge_map_path ],
      [ t("chrome.nav.progress"),    progress_path ],
      [ t("chrome.nav.ranking"),     leaderboard_path ]
    ]

    items << [ t("chrome.nav.instructor"), instructor_path ] if Current.user&.staff?
    items
  end

  # The two staff screens, admin first — it is the admin's index.
  def admin_nav_items
    [
      [ t("chrome.nav.admin"),      admin_path ],
      [ t("chrome.nav.instructor"), instructor_path ]
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
      [ t("chrome.menu.profile"),    my_learning_path ],
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
    %i[learn tracks community events faq].to_h { [ t("landing.nav.#{it}"), "##{it}" ] }
  end

  # The footer's three link columns. Ruby holds only the shape — which columns
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
    (authenticated? ? app_footer_columns : landing_footer_columns).merge(university_footer_column)
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
        events: "#events"
      }
    }
  end

  def app_footer_columns
    {
      learn: {
        catalog: root_path,
        course: course_path("AI1101"),
        map: knowledge_map_path
      },
      track: {
        my_learning: my_learning_path,
        progress: progress_path,
        ranking: leaderboard_path
      }
    }
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
