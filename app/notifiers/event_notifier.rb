# frozen_string_literal: true

# The extension seam of this application.
#
# Something needs to happen when an event changes hands — an organizer wants to
# know a seat was taken, and the next team to pick this up will want that to go
# to email, Slack or a webhook rather than the log. Rather than scattering
# `if Rails.env...` branches through the services, delivery is a named adapter:
#
#   EventNotifier.register(:slack) { SlackEventNotifier.new(webhook_url: ...) }
#
# and `EVENT_NOTIFIER=slack` selects it. Adapters only need to respond to
# `#attendee_joined(event:, attendee:)`.
module EventNotifier
  class UnknownAdapterError < StandardError; end

  # Ignores everything. The safe default for the test suite.
  class NoopAdapter
    def attendee_joined(**) = nil
  end

  # Writes a structured line to the Rails log. The default outside tests.
  class LogAdapter
    def initialize(logger: Rails.logger)
      @logger = logger
    end

    def attendee_joined(event:, attendee:)
      @logger.info(
        "[EventNotifier] attendee_joined event_id=#{event.id} " \
        "event=#{event.name.inspect} attendee_id=#{attendee.id} organizer_id=#{event.organizer_id}"
      )
    end
  end

  ADAPTERS = {
    noop: -> { NoopAdapter.new },
    log: -> { LogAdapter.new }
  }.freeze

  class << self
    # Registers (or replaces) an adapter. The block is called lazily, once.
    def register(name, &factory)
      registry[name.to_sym] = factory
      @adapter = nil if @adapter_name == name.to_sym
    end

    def registry = @registry ||= ADAPTERS.dup

    def adapter_name
      @adapter_name ||= ENV.fetch('EVENT_NOTIFIER', Rails.env.test? ? 'noop' : 'log').to_sym
    end

    def adapter
      @adapter ||= begin
        factory = registry.fetch(adapter_name) do
          raise UnknownAdapterError,
                "Unknown EVENT_NOTIFIER #{adapter_name.inspect}. Known: #{registry.keys.join(', ')}"
        end
        factory.call
      end
    end

    # Test/boot helper: pick an adapter explicitly and drop the memoised instance.
    def use(name)
      @adapter_name = name.to_sym
      @adapter = nil
      adapter
    end

    def reset!
      @adapter = nil
      @adapter_name = nil
    end

    def attendee_joined(event:, attendee:)
      adapter.attendee_joined(event: event, attendee: attendee)
    rescue StandardError => e
      # A notification must never fail the request that triggered it.
      Rails.logger.error("[EventNotifier] delivery failed: #{e.class}: #{e.message}")
      nil
    end
  end
end
