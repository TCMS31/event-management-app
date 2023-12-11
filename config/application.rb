# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EventManagementApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Autoload lib/, except folders that hold no Ruby classes.
    config.autoload_lib(ignore: %w[assets tasks])

    # Nothing here stores uploads, so Active Storage needs no image processor
    # (and stops warning that image_processing is missing).
    config.active_storage.variant_processor = :disabled

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
