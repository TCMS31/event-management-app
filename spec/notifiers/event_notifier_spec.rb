# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventNotifier do
  let(:event)    { create(:event) }
  let(:attendee) { create(:user) }

  after { described_class.reset! }

  it 'defaults to the no-op adapter under test' do
    described_class.reset!

    expect(described_class.adapter).to be_a(described_class::NoopAdapter)
  end

  it 'writes a structured line through the log adapter' do
    logger = instance_double(Logger, info: nil)
    described_class.register(:log_spy) { described_class::LogAdapter.new(logger: logger) }
    described_class.use(:log_spy)

    described_class.attendee_joined(event: event, attendee: attendee)

    expect(logger).to have_received(:info).with(/attendee_joined event_id=#{event.id}/)
  end

  it 'lets a new adapter be registered and selected by name' do
    recorder = Class.new do
      attr_reader :calls

      def initialize = @calls = []
      def attendee_joined(event:, attendee:) = @calls << [event.id, attendee.id]
    end.new

    described_class.register(:recorder) { recorder }
    described_class.use(:recorder)

    described_class.attendee_joined(event: event, attendee: attendee)

    expect(recorder.calls).to eq([[event.id, attendee.id]])
  end

  it 'raises a clear error for an adapter nobody registered' do
    described_class.use(:nope)
  rescue described_class::UnknownAdapterError => e
    expect(e.message).to include('Unknown EVENT_NOTIFIER :nope')
  else
    raise 'expected UnknownAdapterError'
  end

  it 'swallows a delivery failure so the request still succeeds' do
    described_class.register(:exploding) { Class.new { def attendee_joined(**) = raise('boom') }.new }
    described_class.use(:exploding)

    expect { described_class.attendee_joined(event: event, attendee: attendee) }.not_to raise_error
  end
end
