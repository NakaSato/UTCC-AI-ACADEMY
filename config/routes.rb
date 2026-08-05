Rails.application.routes.draw do
  # Auth reads as plain English in the address bar rather than as REST resources:
  # a student sees /login, not /session/new. One path per screen, one helper per
  # path — login_path serves both the form and its POST.
  get  "login",  to: "sessions#new",     as: :login
  post "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

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

  # The policy documents. Public, and named for what they are rather than nested
  # under a /policies prefix nobody would type.
  get "privacy", to: "policies#privacy", as: :privacy
  get "terms", to: "policies#terms", as: :terms

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
  # GET because it is a read, and it exists because a broadcast has no session:
  # this request carries the reader's own cookies, and so their language and their
  # CSRF token. See NotificationBell.
  get "notifications", to: "notifications#show", as: :notifications
  # The bell's "mark all read" — one write, back to where you were.
  post "notifications/read", to: "notifications#read_all", as: :read_notifications
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
  get "academic-post-invitations/:token", to: "academic_post_invitations#show", as: :academic_post_invitation
  post "academic-post-invitations/:token/accept", to: "academic_post_invitations#accept", as: :accept_academic_post_invitation

  # /instructor needs the instructor or admin role, /admin the admin role — see
  # the Authorization concern and each controller's `allow_only`.
  get "admin", to: "admin#show", as: :admin
  patch "admin/users/:id", to: "admin#update", as: :admin_user
  patch "admin/courses/:id/state", to: "admin#update_course_state", as: :admin_course_state
  post "admin/approvals/:id/decision", to: "admin#decide_approval", as: :admin_approval_decision
  patch "admin/features/:key", to: "admin#update_feature_setting", as: :admin_feature_setting
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
