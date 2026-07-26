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
  get "lesson", to: "lessons#show", as: :lesson
  # Where the browser sends an exercise answer or a coding task to be graded —
  # see LessonsController#submit. It replaced lesson/complete, which took the
  # browser's word for a pass.
  post "lesson/submit", to: "lessons#submit", as: :submit_lesson
  get "my-learning", to: "my_learning#show", as: :my_learning
  get "map", to: "knowledge_maps#show", as: :knowledge_map
  get "progress", to: "progress#show", as: :progress
  get "leaderboard", to: "leaderboards#show", as: :leaderboard
  get "instructor", to: "instructor#show", as: :instructor

  # /instructor needs the instructor or admin role, /admin the admin role — see
  # the Authorization concern and each controller's `allow_only`.
  get "admin", to: "admin#show", as: :admin
  patch "admin/users/:id", to: "admin#update", as: :admin_user

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
