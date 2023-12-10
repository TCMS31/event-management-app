# syntax=docker/dockerfile:1

# ---------- build ----------------------------------------------------------
# Compiles native gem extensions and the Bootstrap stylesheet, so the runtime
# image needs neither a compiler nor Node.
FROM ruby:3.1.3-slim AS build

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y \
      build-essential git libpq-dev pkg-config curl ca-certificates \
 && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install --no-install-recommends -y nodejs \
 && npm install -g yarn@1.22.22 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /rails

# Gems first: this layer is cached until Gemfile.lock changes.
COPY Gemfile Gemfile.lock ./
RUN bundle install \
 && rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Then node modules, for the same reason.
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .

# Build the CSS bundle and precompile assets. SECRET_KEY_BASE_DUMMY lets the
# app initialise without the real production secret.
RUN yarn build:css \
 && SECRET_KEY_BASE=dummy bundle exec rails assets:precompile \
 && rm -rf node_modules tmp/cache log/*

# ---------- runtime --------------------------------------------------------
FROM ruby:3.1.3-slim AS runtime

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    PORT=3000

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y libpq5 curl tzdata \
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
