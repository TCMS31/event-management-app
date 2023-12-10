# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventSerializer do
  let(:organizer) { create(:user) }
  let(:event)     { create(:event, organizer: organizer, date: Time.utc(2026, 6, 1, 9, 0)) }

  def serialize(event, viewer)
    ActiveModelSerializers::SerializableResource
      .new(event, scope: Viewer.new(viewer), adapter: :attributes)
      .as_json
      .deep_stringify_keys
  end

  it 'exposes the start time as ISO 8601 with the time of day' do
    expect(serialize(event, organizer)['date']).to eq('2026-06-01T09:00:00Z')
  end

  it 'leaves a missing start time as null instead of raising' do
    event.update_column(:date, nil)

    expect(serialize(event.reload, organizer)['date']).to be_nil
  end

  it 'only exposes id and email for the organizer' do
    expect(serialize(event, organizer)['organizer'].keys).to contain_exactly('id', 'email')
  end

  it 'marks the event editable for its organizer only' do
    expect(serialize(event, organizer)['editable']).to be(true)
    expect(serialize(event, create(:user))['editable']).to be(false)
  end

  it 'reports whether the viewer has joined' do
    attendee = create(:user)

    expect(serialize(event, attendee)['joined']).to be(false)

    create(:event_attendance, event: event, attendee: attendee)

    expect(serialize(event, attendee.reload)['joined']).to be(true)
  end
end
