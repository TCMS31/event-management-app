# frozen_string_literal: true

# Idempotent development seed data.
# Run with: bin/rails db:seed

ORGANIZERS = [
  { email: 'ayesha.khan@example.com', name: 'Ayesha Khan' },
  { email: 'marcus.doyle@example.com', name: 'Marcus Doyle' },
  { email: 'lena.oduya@example.com', name: 'Lena Oduya' }
].freeze

ATTENDEES = %w[
  sam.rivera@example.com priya.nair@example.com tom.becker@example.com
  hana.sato@example.com david.olsen@example.com
].freeze

EVENTS = [
  { name: 'Rails Performance Day',   location: 'Lahore Tech Park, Hall B', in_days: 6,
    description: 'A full day on profiling Rails apps: N+1 hunting, database indexes, caching layers and background jobs.' },
  { name: 'Hotwire in Practice',     location: 'Berlin Mitte Studio',      in_days: 13,
    description: 'Turbo Frames, Turbo Streams and Stimulus patterns for teams migrating away from a separate SPA front end.' },
  { name: 'PostgreSQL Index Clinic', location: 'Remote (Zoom)',            in_days: 20,
    description: 'Bring a slow query. We read the EXPLAIN plan together and work out which index actually helps.' },
  { name: 'Design Systems Meetup',   location: 'Nairobi Innovation Hub',   in_days: 27,
    description: 'How small product teams keep a component library honest without a dedicated design ops function.' },
  { name: 'Open Source Fridays',     location: 'Amsterdam Zuid Cowork',    in_days: 34,
    description: 'A recurring co-working session for maintainers: triage issues, review pull requests, pair on hard bugs.' },
  { name: 'Testing Legacy Code',     location: 'Manchester Science Park',  in_days: 41,
    description: 'Characterisation tests, seams and safe refactors for codebases that arrived without a test suite.' },
  { name: 'Background Jobs 101',     location: 'Dublin Docklands Loft',    in_days: 48,
    description: 'Moving slow work off the request cycle: queue choice, idempotency, retries and dead-letter handling.' },
  { name: 'Accessible Forms Lab',    location: 'Toronto East Studio',      in_days: 55,
    description: 'Labels, focus order, error summaries and live regions, checked against a screen reader as we go.' },
  { name: 'API Versioning Round',    location: 'Remote (Zoom)',            in_days: 62,
    description: 'Round-table on shipping breaking changes without breaking clients, with three war stories.' },
  { name: 'Observability Evening',   location: 'Lisbon Riverside Hub',     in_days: 69,
    description: 'Structured logs, traces and the three dashboards a small team actually reads during an incident.' },
  { name: 'Docker for Rails Teams',  location: 'Warsaw Praga Workshop',    in_days: 76,
    description: 'Multi-stage builds, small runtime images and a compose file that matches what CI actually runs.' },
  { name: 'Refactoring Book Club',   location: 'Copenhagen Nord Cafe',     in_days: 83,
    description: 'Monthly reading group. This month: extracting service objects from a controller that grew too large.' }
].freeze

password = ENV.fetch('SEED_PASSWORD', 'password123')

organizers = ORGANIZERS.map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) { |u| u.password = password }
end

attendees = ATTENDEES.map do |email|
  User.find_or_create_by!(email: email) { |u| u.password = password }
end

events = EVENTS.each_with_index.map do |attrs, i|
  Event.find_or_create_by!(name: attrs[:name]) do |e|
    e.description = attrs[:description]
    e.location    = attrs[:location]
    e.date        = Time.current.beginning_of_day + attrs[:in_days].days + 18.hours + 30.minutes
    e.organizer   = organizers[i % organizers.size]
  end
end

# Rotate the attendee list so the seeded data has a realistic mix: some events
# busy, some quiet, and no single user signed up to everything.
events.each_with_index do |event, i|
  going = attendees.rotate(i).first((i % 4) + 1)
  going.each { |attendee| EventAttendance.find_or_create_by!(event: event, attendee: attendee) }
end

puts "Seeded #{User.count} users and #{Event.count} events " \
     "(#{EventAttendance.count} attendances). Sign in as #{organizers.first.email} / #{password}"
