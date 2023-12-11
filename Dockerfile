# syntax=docker/dockerfile:1

# ---------- stylesheet -----------------------------------------------------
# Bootstrap is compiled with Node here, so neither Ruby stage needs Node.
FROM node:22-bookworm-slim AS css

WORKDIR /rails
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --network-timeout 600000

COPY app/assets/stylesheets app/assets/stylesheets
RUN mkdir -p app/assets/builds && yarn build:css

# ---------- gems and assets ------------------------------------------------
# The full Ruby image already carries a compiler, libpq-dev and libyaml-dev for
# the native gems (pg, psych, bcrypt, puma), so this stage installs no packages.
FROM ruby:3.4.12 AS build

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

WORKDIR /rails

# Gems first: this layer is cached until Gemfile.lock changes.
COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install \
 && rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .
COPY --from=css /rails/app/assets/builds/application.css app/assets/builds/application.css

# A throwaway SECRET_KEY_BASE lets the app boot far enough to precompile.
# SKIP_CSS_BUILD stops cssbundling from re-running `yarn build:css` here, where
# there is no Node; the stylesheet already came from the css stage.
RUN SECRET_KEY_BASE_DUMMY=1 SKIP_CSS_BUILD=1 bundle exec rails assets:precompile \
 && rm -rf tmp/cache log/*

# ---------- runtime --------------------------------------------------------
FROM ruby:3.4.12-slim AS runtime

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    PORT=3000

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y libpq5 libyaml-0-2 curl tzdata \
 && rm -rf /var/lib/apt/lists/*

# Run as an unprivileged user.
RUN groupadd --system --gid 1000 rails \
 && useradd --system --uid 1000 --gid rails --create-home rails

WORKDIR /rails

COPY --from=build --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails

USER rails:rails

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS "http://127.0.0.1:${PORT}/health" || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
