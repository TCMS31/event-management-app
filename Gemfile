# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: '.ruby-version'

gem 'rails', '~> 8.1.4'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.6'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 8.0'

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# User authentication
gem 'devise', '~> 5.0'

gem 'active_model_serializers', '~> 0.10.16'

# Bootstrap is compiled by `yarn build:css` into app/assets/builds
gem 'cssbundling-rails'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'

  # Static analysis
  gem 'rubocop', '~> 1.92', require: false
  gem 'rubocop-factory_bot', '~> 2.28', require: false
  gem 'rubocop-rails', '~> 2.38', require: false
  gem 'rubocop-rspec', '~> 3.10', require: false
  gem 'rubocop-rspec_rails', '~> 2.33', require: false

  # Test suite
  gem 'rspec-rails', '~> 8.1'

  gem 'shoulda-matchers', '~> 8.0'

  gem 'factory_bot_rails'

  gem 'faker'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'
end
