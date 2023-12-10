# frozen_string_literal: true

# The API envelopes every payload under a root key; these keep the specs readable.
module JsonHelpers
  def json_body = JSON.parse(response.body)
  def json_event = json_body.fetch('event')
  def json_events = json_body.fetch('events')
  def json_meta = json_body.fetch('meta')
end

RSpec.configure do |config|
  config.include JsonHelpers, type: :request
end
