# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Events::Join do
  let(:user)  { create(:user) }
  let(:event) { create(:event) }

  it 'records the attendance and succeeds' do
    result = described_class.call(event: event, user: user)

    expect(result).to be_success
    expect(result.status).to eq(:ok)
    expect(event.reload.attendees).to include(user)
  end

  it 'returns a 409 conflict on a second join rather than raising' do
    described_class.call(event: event, user: user)

    result = described_class.call(event: event, user: user.reload)

    expect(result).to be_failure
    expect(result.status).to eq(:conflict)
    expect(EventAttendance.where(event: event, attendee: user).count).to eq(1)
  end

  it 'returns 403 when the organizer tries to join their own event' do
    own = create(:event, organizer: user)

    result = described_class.call(event: own, user: user)

    expect(result).to be_failure
    expect(result.status).to eq(:forbidden)
  end

  it 'turns a lost race on the unique index into a conflict, not a 500' do
    allow(EventAttendance).to receive(:new).and_return(instance_double(EventAttendance).tap do |double|
      allow(double).to receive(:save).and_raise(ActiveRecord::RecordNotUnique, 'duplicate key')
    end)

    result = described_class.call(event: event, user: user)

    expect(result).to be_failure
    expect(result.status).to eq(:conflict)
  end

  it 'notifies through the configured notifier' do
    EventNotifier.use(:noop)
    allow(EventNotifier.adapter).to receive(:attendee_joined)

    described_class.call(event: event, user: user)

    expect(EventNotifier.adapter).to have_received(:attendee_joined).with(event: event, attendee: user)
  end

  it 'still joins the event when the notifier blows up' do
    EventNotifier.register(:exploding) { Class.new { def attendee_joined(**) = raise('boom') }.new }
    EventNotifier.use(:exploding)

    result = described_class.call(event: event, user: user)

    expect(result).to be_success
    expect(event.reload.attendees).to include(user)
  end
end
