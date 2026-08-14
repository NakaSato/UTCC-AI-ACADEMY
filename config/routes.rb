Rails.application.routes.draw do
  # Auth reads as plain English in the address bar rather than as REST resources:
  # a student sees /login, not /session/new. One path per screen, one helper per
  # path — login_path serves both the form and its POST.
  get  "login",  to: "sessions#new",     as: :login
  post "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  # The staff and company way in. Same shape as /login — one path, one helper,
  # both verbs — and a separate screen because it asks for a different credential
  # and opens a different set of screens. See ConsoleSessionsController.
  get  "console", to: "console_sessions#new",    as: :console
  post "console", to: "console_sessions#create"

  get  "register", to: "registrations#new",    as: :register
  post "register", to: "registrations#create"

  get  "forgot-password", to: "passwords#new",    as: :forgot_password
  post "forgot-password", to: "passwords#create"
  get "reset-password/:token", to: "passwords#edit",   as: :reset_password
  put "reset-password/:token", to: "passwords#update"

  # The generator's URLs, kept alive so reset links already sitting in inboxes
  # still resolve. Nothing in the app links here.
  get "session/new",      to: redirect("/login")
  get "registration/new", to: redirect("/register")
  get "passwords/new",    to: redirect("/forgot-password")
  get "passwords/:token/edit", to: redirect("/reset-password/%{token}")

  # POST rather than GET: Turbo prefetches links on hover, and a GET here would
  # switch language just by pointing at the button.
  post "language/:locale", to: "languages#update", as: :language,
       constraints: { locale: /th|en/ }

  # The palette toggle, same shape and for the same reason: a GET would repaint
  # the app on hover. "system" clears the preference rather than storing a third
  # value — see ThemesController.
  post "theme/:theme", to: "themes#update", as: :theme,
       constraints: { theme: /light|dark|system/ }

  # The policy documents. Public, and named for what they are rather than nested
  # under a /policies prefix nobody would type.
  get "privacy", to: "policies#privacy", as: :privacy
  get "terms", to: "policies#terms", as: :terms
  get "contributors", to: "contributors#index", as: :contributors

  # What a crawler reads before it reads a page. Rendered rather than checked into
  # public/ because each one has to name absolute URLs and only the request knows
  # the host — see CrawlersController.
  get "robots.txt", to: "crawlers#robots", as: :robots, defaults: { format: :text }
  get "sitemap.xml", to: "crawlers#sitemap", as: :sitemap, defaults: { format: :xml }
  get "llms.txt", to: "crawlers#llms", as: :llms, defaults: { format: :text }

  # The app proper. Everything here requires a session — see the Authentication
  # concern, which adds `before_action :require_authentication` globally.
  resources :courses, only: :show, param: :code
  get "courses/:code/syllabus.pdf", to: "course_documents#syllabus", as: :course_syllabus
  get "lesson", to: "lessons#show", as: :lesson
  # Where the browser sends an exercise answer or a coding task to be graded —
  # see LessonsController#submit. It replaced lesson/complete, which took the
  # browser's word for a pass.
  post "lesson/submit", to: "lessons#submit", as: :submit_lesson
  # The proctor reporting what it saw — see LessonsController#incident. The
  # browser is reporting evidence against itself, which is why this is the one
  # post the lock does not guard.
  post "lesson/incident", to: "lessons#incident", as: :lesson_incident
  # The bell on its own, for the frame a broadcast pushes to come back to. It is a
  # The reader's own history, and the route the ninth notification was missing:
  # the bell shows the most recent eight and nothing reached past them, on the
  # only channel there is while production email is deferred (ADR-0052).
  get "notifications", to: "notifications#show", as: :notifications
  # The bell itself, which the header's frame comes back for. GET because it is
  # a read, and separate because a broadcast has no session: this request
  # carries the reader's own cookies, and so their language and their CSRF
  # token. See NotificationBell. The readable URL belongs to the reader's
  # screen, not to the header's implementation detail.
  get "notifications/bell", to: "notifications#bell", as: :notifications_bell
  # The bell's "mark all read" — one write, back to where you were.
  post "notifications/read", to: "notifications#read_all", as: :read_notifications
  # A company's own screens live at /company/:slug — the profile and everything
  # scoped to it. `path` and `as` are set because the code's name for the record
  # is Organization and the URL's name for it is a company; the model keeps the
  # general word, the address uses the one a visitor would.
  #
  # Declared outside `namespace :recruitment` and pointed back into it with
  # `module:`, so the controllers stay where they are while the URL stops
  # spelling out an internal namespace. `to_param` is the slug, so `:id` and
  # `:organization_id` both carry the name — no controller reads an id here.
  scope module: :recruitment do
    resources :organizations, path: "company", as: :companies, only: %i[index new create show] do
      # Where a company member lands. The slug root is the company's record;
      # this is the work waiting on it. ADR-0048.
      get :work, on: :member, to: "company_work#show"
      get :reporting, on: :member, to: "reporting#show"
      post :memberships, on: :member, to: "organizations#create_membership"
      delete "memberships/:user_id", on: :member, to: "organizations#revoke_membership",
             as: :membership
      post :invitations, on: :member, to: "organization_invitations#create"
      # Two screens that belong to a company but not to the recruitment module —
      # the leading slash is what keeps them out of it. They live here so a
      # company has one namespace rather than one per feature that touches it.
      resources :internship_requests, path: "internship", only: :index,
                controller: "/internship_request_decisions", as: :internship_requests
      patch "internship/settings", to: "/organization_internship_settings#update",
            as: :internship_request_settings
      resources :job_posts, only: %i[index new create show edit update destroy] do
        post :submit, on: :member
        post :request_changes, on: :member
        post :publish, on: :member
        post :pause, on: :member
        post :close, on: :member
        post :archive, on: :member
        post :suggestions, on: :member, to: "job_suggestions#create"
        resources :suggestions, only: :update, controller: "job_suggestions" do
          post :accept, on: :member
          post :reject, on: :member
          post :regenerate, on: :member
        end
        resources :applications, only: %i[index show], controller: "job_applications" do
          post :transition, on: :member
          post :message, on: :member
        end
      end
      resources :internship_programs, only: %i[index new create show edit update] do
        post :submit, on: :member
        post :request_changes, on: :member
        post :publish, on: :member
        post :pause, on: :member
        post :close, on: :member
        post :archive, on: :member
        post :suggestions, on: :member, to: "internship_suggestions#create"
        resources :suggestions, only: :update, controller: "internship_suggestions" do
          post :accept, on: :member
          post :reject, on: :member
          post :regenerate, on: :member
        end
        # No index: the program's own screen lists its applications with the
        # decide and evaluate controls on them, and the second screen that used
        # to be routed here had no template — an authorized reader would have
        # met a missing-template error, and nothing ever linked to it.
        resources :applications, only: [], controller: "internship_applications" do
          post :accept, on: :member
          post :reject, on: :member
          resource :evaluation, only: %i[create update], controller: "internship_evaluations"
        end
      end
    end
  end

  # The candidate's half of recruitment keeps its own prefix: these are screens
  # about jobs and applications rather than about one company, and /recruitment
  # is a section a student browses rather than an internal namespace leaking out.
  namespace :recruitment do
    resources :jobs, only: %i[index show], controller: :job_posts
    resources :job_applications, only: %i[index show], path: "job-applications", controller: :job_applications
    post "jobs/:id/apply", to: "job_applications#create", as: :apply_job
    post "job-applications/:id/withdraw", to: "job_applications#withdraw", as: :withdraw_job_application
    post "job-applications/:id/messages", to: "job_applications#message", as: :message_job_application
    post "jobs/:id/save", to: "saved_jobs#create", as: :save_job
    delete "jobs/:id/save", to: "saved_jobs#destroy", as: :unsave_job
    post "jobs/:id/dismiss", to: "job_discovery_dismissals#create", as: :dismiss_job_recommendation
    delete "jobs/:id/dismiss", to: "job_discovery_dismissals#destroy", as: :undismiss_job_recommendation
    resource :job_discovery_preferences, only: %i[edit update], path: "job-discovery/preferences",
             controller: :job_discovery_preferences
    resources :internships, only: %i[index show], controller: :internship_programs
    post "internships/:id/apply", to: "internship_applications#create", as: :apply_internship
    post "internship-applications/:id/withdraw", to: "internship_applications#withdraw",
         as: :withdraw_internship_application
    resource :candidate_profile, only: %i[edit update],
             path: "candidate-profile", controller: :candidate_profiles
    get "candidate-profile/export", to: "candidate_profiles#export", as: :candidate_profile_export
    delete "candidate-profile", to: "candidate_profiles#destroy", as: :candidate_profile_data
    post "candidate-profile/resume-analysis", to: "candidate_resume_analyses#create",
         as: :candidate_profile_resume_analysis
    patch "candidate-profile/resume-analysis/:analysis_id/findings/:id", to: "candidate_resume_analyses#update",
          as: :candidate_resume_analysis_finding
    post "candidate-profile/resume-analysis/:analysis_id/findings/:id/accept", to: "candidate_resume_analyses#accept",
         as: :accept_candidate_resume_analysis_finding
    post "candidate-profile/resume-analysis/:analysis_id/findings/:id/reject", to: "candidate_resume_analyses#reject",
         as: :reject_candidate_resume_analysis_finding
    post "candidate-profile/resume-analysis/:id/apply", to: "candidate_resume_analyses#apply",
         as: :apply_candidate_resume_analysis
    get "organization-invitations/:token", to: "organization_invitations#show",
        as: :organization_invitation
    post "organization-invitations/:token/accept", to: "organization_invitations#accept",
         as: :accept_organization_invitation
    post "organization-invitations/:token/decline", to: "organization_invitations#decline",
         as: :decline_organization_invitation
  end
  get "my-learning", to: "my_learning#show", as: :my_learning
  # The account's own details. One helper for both verbs, like the auth screens:
  # profile_path is the link and the form action. This is the only place an
  # account acquires an email address — sign-up does not ask for one.
  get "profile", to: "profiles#edit", as: :profile
  patch "profile", to: "profiles#update"
  # Changing a password while signed in. Its own path because it is its own form
  # with its own errors, sharing the screen rather than the action — and because
  # the reset flow under /reset-password is the signed-*out* way in and answers a
  # different question.
  patch "profile/password", to: "profiles#update_password", as: :profile_password
  delete "profile/sessions", to: "sessions#destroy_other_sessions", as: :revoke_other_sessions
  delete "profile/sessions/:token", to: "sessions#destroy_session", as: :revoke_profile_session
  get "map", to: "knowledge_maps#show", as: :knowledge_map
  post "map/known", to: "prior_knowledges#create", as: :mark_topic_known
  delete "map/known", to: "prior_knowledges#destroy", as: :unmark_topic_known
  get "progress", to: "progress#show", as: :progress
  get "leaderboard", to: "leaderboards#show", as: :leaderboard
  get "instructor", to: "instructor#show", as: :instructor
  # The Teaching console's one download: the roster as CSV. A plain-word URL
  # like every other, and the same staff gate as the screen.
  get "instructor/grades", to: "instructor#grades", as: :instructor_grades
  patch "instructor/integrity/:topic_key", to: "instructor#update_integrity_setting",
        as: :instructor_integrity_setting
  # A teacher’s two writes over the course they teach (ADR-0054): its numbers,
  # while it is a draft, and a request to move its lifecycle — which an
  # administrator decides in the queue, exactly as one of their own.
  patch "instructor/course", to: "instructor#update_course", as: :instructor_course
  post "instructor/course/transition", to: "instructor#request_course_transition",
       as: :instructor_course_transition
  # And the two edits to the syllabus itself: what a lesson is called, and what
  # order the lessons come in. Both draft-only and both their own course's, like
  # the numbers above. Adding and removing a lesson is not here — that is a
  # request, and it goes through the queue.
  patch "instructor/syllabus/topic/:topic_key", to: "instructor#rename_topic",
        as: :instructor_syllabus_topic
  patch "instructor/syllabus/move/:topic_key", to: "instructor#move_topic",
        as: :instructor_syllabus_move
  # Adding one changes what exists, so it is a request rather than a write — the
  # same queue, the same second pair of eyes, as publishing the course.
  post "instructor/syllabus/lesson", to: "instructor#request_lesson",
       as: :instructor_syllabus_lesson
  # And taking one out, which is a retirement rather than a delete (ADR-0055) and
  # goes through the same queue.
  post "instructor/syllabus/retire/:topic_key", to: "instructor#request_retirement",
       as: :instructor_syllabus_retire

  # Public surface is /academic. Keep the internal resource name and helpers
  # stable so AcademicPost records, associations, and existing callers do not
  # require a database migration.
  resources :academic_posts, path: "academic", only: %i[index new create show edit update] do
    post :submit, on: :member
    post :publish, on: :member
    post :pictures, on: :member
    get :export, on: :member
    post :invitations, on: :member, to: "academic_post_invitations#create"
    delete "memberships/:user_id", to: "academic_post_invitations#revoke", as: :membership
  end
  resources :proposal_requests, path: "proposal-requests", only: %i[new create show]
  get "academic-post-invitations/:token", to: "academic_post_invitations#show", as: :academic_post_invitation
  post "academic-post-invitations/:token/accept", to: "academic_post_invitations#accept", as: :accept_academic_post_invitation

  # Business-case collaboration (SPEC-0040, Phase 1). Invitation-only and
  # text-only: the boundary test reads this delimited block to prove no file,
  # mailer, or API surface ships before its review decisions exist.
  resources :business_cases, path: "business-cases", only: %i[index new create show edit update] do
    post :publish, on: :member
    post :close, on: :member
    post :invitations, on: :member, to: "business_case_invitations#create"
    post :participants, on: :member, to: "business_case_participants#create"
    delete "participants/:user_id", on: :member, to: "business_case_participants#revoke", as: :participant
    post :milestones, on: :member, to: "business_case_milestones#create"
    post "milestones/:milestone_id/complete", on: :member, to: "business_case_milestones#complete",
         as: :complete_milestone
    post "milestones/:milestone_id/submissions", on: :member, to: "business_case_submissions#create",
         as: :milestone_submissions
    post :comments, on: :member, to: "business_case_comments#create"
  end
  get "business-case-invitations/:token", to: "business_case_invitations#show", as: :business_case_invitation
  post "business-case-invitations/:token/accept", to: "business_case_invitations#accept",
       as: :accept_business_case_invitation
  post "business-case-invitations/:token/decline", to: "business_case_invitations#decline",
       as: :decline_business_case_invitation
  # End business-case collaboration

  # Internship requests (SPEC-0041, increment 1). Student-initiated and strictly
  # position-less; published positions are reached through the recruitment
  # internship routes above. The boundary test reads this delimited block to
  # prove no placement, progress-report, faculty, document, mailer, or API
  # surface ships before each has its own recorded decision.
  resources :internship_requests, path: "internship-requests", only: %i[index new create edit update show] do
    post :submit, on: :member
    post :withdraw, on: :member
    # The shared résumé (SPEC-0041, increment 4). No upload here: the file is
    # the one already on the student's candidate profile, and these three say
    # who shared it, who unshared it, and who may read it.
    post :resume, on: :member, to: "internship_request_resumes#create"
    delete :resume, on: :member, to: "internship_request_resumes#destroy", as: :unshare_resume
    get :resume, on: :member, to: "internship_request_resumes#show", as: :download_resume
  end
  post "internship-requests/:id/review", to: "internship_request_decisions#review", as: :review_internship_request
  post "internship-requests/:id/approve", to: "internship_request_decisions#approve", as: :approve_internship_request
  post "internship-requests/:id/reject", to: "internship_request_decisions#reject", as: :reject_internship_request

  # Placements and weekly progress reports (SPEC-0041, increment 2). A placement
  # originates from an approved request or an accepted recruitment application,
  # and is the only record that says an internship is happening.
  resources :internship_placements, path: "internships/placements", only: %i[index show create] do
    post :activate, on: :member
    post :complete, on: :member
    post :cancel, on: :member
    post :reports, on: :member, to: "internship_progress_reports#create"
    post "reports/:report_id/acknowledge", on: :member,
         to: "internship_progress_reports#acknowledge", as: :acknowledge_report
    # Faculty oversight (SPEC-0041, increment 3, ADR-0041 decision 2 answered
    # 2026-08-12). An administrator assigns and revokes; the supervisor reads
    # and acknowledges. There is deliberately no route that lets them approve,
    # advance, or complete anything, and the boundary test checks for it.
    post :faculty, on: :member, to: "internship_faculty_assignments#create"
    delete "faculty/:assignment_id", on: :member,
           to: "internship_faculty_assignments#destroy", as: :revoke_faculty
    post "reports/:report_id/faculty-acknowledge", on: :member,
         to: "internship_progress_reports#faculty_acknowledge", as: :faculty_acknowledge_report
    # Deliverables (SPEC-0041, increment 4). The download is an app route rather
    # than a blob URL on purpose: a signed blob URL authorizes the link and
    # outlives both the placement and the membership that justified it.
    post :deliverables, on: :member, to: "internship_deliverables#create"
    delete "deliverables/:deliverable_id", on: :member,
           to: "internship_deliverables#destroy", as: :deliverable
    get "deliverables/:deliverable_id/download", on: :member,
        to: "internship_deliverables#download", as: :download_deliverable
  end
  # End internship requests

  # /instructor needs the instructor or admin role, /admin the admin role — see
  # the Authorization concern and each controller's `allow_only`.
  get "admin", to: "admin#show", as: :admin
  patch "admin/users/:id", to: "admin#update", as: :admin_user
  # Where a console account comes from. Sign-up produces learners only, so an
  # instructor, an administrator, or a company member is made here or nowhere.
  post "admin/console-accounts", to: "admin#create_console_account", as: :admin_console_accounts
  # A console account's only way back in when the one-time password is gone: it
  # has no student ID and its owner may not reach the email reset. See
  # AdminController#reissue_password.
  post "admin/users/:id/password", to: "admin#reissue_password", as: :admin_user_password
  patch "admin/courses/:id/state", to: "admin#update_course_state", as: :admin_course_state
  post "admin/approvals/:id/decision", to: "admin#decide_approval", as: :admin_approval_decision
  # One recorded answer to a proposal, with the reason its author reads.
  # ADR-0049 decision 5 and SPEC-0050.
  post "admin/proposals/:id/decision", to: "admin#decide_proposal", as: :admin_proposal_decision
  patch "admin/features/:key", to: "admin#update_feature_setting", as: :admin_feature_setting
  # The Overview tab's downloads. A whitelist of three, each counted off the same
  # tables the screens above them read.
  get "admin/reports/:report", to: "admin#report", as: :admin_report
  # Closing an integrity case stamps a learner's unreviewed proctor events.
  post "admin/integrity/:user_id/close", to: "admin#close_case", as: :close_integrity_case
  # The other two case actions write a notification — to the student, and to
  # the instructor of the student's section for that course.
  post "admin/integrity/:user_id/notify", to: "admin#notify_case", as: :notify_integrity_case
  post "admin/integrity/:user_id/escalate", to: "admin#escalate_case", as: :escalate_integrity_case
  # Section management: real records, admin only. Creating a section, pointing
  # an instructor at it, and putting students in it are the three writes a
  # deployment needs before anyone can use the cohort features.
  post "admin/sections", to: "admin#create_section", as: :admin_sections
  patch "admin/sections/:id", to: "admin#update_section", as: :admin_section
  post "admin/sections/:id/enrol", to: "admin#enrol", as: :admin_enrol
  delete "admin/sections/:id/enrol/:user_id", to: "admin#unenrol", as: :admin_unenrol
  # The marketing landing page. Its copy is `landing_texts` over the locale
  # files, which are still what ships; its cards are `landing_cards`, which is
  # what makes a topic or an event something an admin adds rather than a deploy.
  patch "admin/landing", to: "admin#update_landing", as: :admin_landing
  post "admin/landing/cards", to: "admin#create_card", as: :admin_landing_cards
  patch "admin/landing/cards/:id/move", to: "admin#move_card", as: :move_admin_landing_card
  delete "admin/landing/cards/:id", to: "admin#destroy_card", as: :admin_landing_card

  # The error screens. `config.exceptions_app` rewrites a failed request's path
  # to its status code and dispatches it back through the router, so this one
  # route answers every status Rails can raise — and every verb, because a POST
  # that raised arrives here as a POST rather than as a GET of /500.
  #
  # Constrained to 4xx and 5xx so it stays an error route and not a catch-all:
  # /700 is a page that does not exist, and is answered as one.
  #
  match "/:code", to: "errors#show", via: :all, as: :error,
        constraints: { code: /[45]\d\d/ }

  # The flat files in public/ answer /404 and /500 first whenever the static
  # file server is on — the router never sees those requests. Only a dispatch
  # from `exceptions_app` reaches the route above, which is the traffic that
  # matters, but it leaves the live pages with no address anyone can open. This
  # is that address: /errors/404 is how the pages are reviewed, screenshotted
  # and tested.
  get "errors/:code", to: "errors#show", as: :error_preview,
      constraints: { code: /[45]\d\d/ }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # The catalog for signed-in students, /admin for an admin, the public landing
  # page for everyone else.
  root "home#index"
end
