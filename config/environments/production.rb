require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Nothing in this app uploads or renders an image, so `image_processing` (and the
  # libvips it wants) is not in the Gemfile. Saying so explicitly is what stops Active
  # Storage warning about the missing gem on every boot.
  config.active_storage.variant_processor = :disabled

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  #
  # Render terminates TLS before forwarding to Thruster. Kamal would do the same
  # through its proxy if that deferred target is ever selected. Without this,
  # Rails believes every request arrived unencrypted. That is not only a cookie
  # problem: request.base_url builds every canonical, hreflang and sitemap URL.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint, which the
  # proxy and any uptime monitor reach over plain http from inside the network.
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  #
  # No `solid_queue.connects_to`: the queue tables are in the primary database,
  # so Solid Queue uses the connection the app already has rather than opening a
  # pool of its own. See the note in config/database.yml for the connection
  # budget that decides this.
  config.active_job.queue_adapter = :solid_queue

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  #
  # Unlike every other URL the app publishes, a mailer's cannot be built from the
  # request — there isn't one. The password-reset link is the only mail this app
  # sends, and it is unusable if this is wrong. `protocol` is spelled out because
  # force_ssl only rewrites what the server answers, not what the mailer writes.
  config.action_mailer.default_url_options = { host: "academy.boring9.dev", protocol: "https" }

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via bin/rails credentials:edit.
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  #
  # This is the list of names the app will answer to, and it is a second reason to
  # keep it short: `request.base_url` builds every canonical, hreflang and sitemap
  # <loc>, so a name that reaches the app is a name that can get itself published.
  #
  # Both entries are spelled out. A `/\A.*\.onrender\.com\z/` wildcard used to
  # stand here, and anyone can own a free name under that domain — a forged Host
  # would have come back inside the canonical, the hreflang set, og:image, the
  # JSON-LD url and every sitemap <loc>. The exact service name is `name:` in
  # render.yaml, and this line can lose it once academy.boring9.dev's certificate
  # is issued.
  config.hosts = [
    "academy.boring9.dev",
    "utcc-ai-academy.onrender.com"
  ]

  # Skip DNS rebinding protection for the default health check endpoint, which the
  # platform reaches from inside the network under whatever name it likes.
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
