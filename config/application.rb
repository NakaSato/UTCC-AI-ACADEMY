require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module UtccAiFundamental
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks templates])

    # Thai-first: the UI ships in both languages, and Thai is what a student
    # sees unless they ask otherwise. English backs Thai up so a key that only
    # exists in en.yml renders rather than raising.
    config.i18n.default_locale = :th
    config.i18n.available_locales = %i[ th en ]
    config.i18n.fallbacks = [ :en ]

    # Failed requests are re-dispatched through the router instead of being
    # answered with the flat files in public/. That is what makes an error page
    # a page: bilingual, on the brand, and carrying the request id a support
    # message needs. The flat files stay as the fallback for a failure too early
    # for a controller to run — see ErrorsController and HttpError.
    config.exceptions_app = routes

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
