# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:organized_events).class_name('Event').with_foreign_key('organizer_id') }
    it { is_expected.to have_many(:event_attendances).dependent(:destroy) }
    it { is_expected.to have_many(:attended_events).through(:event_attendances).source(:event) }
  end

  describe '#attending?' do
    let(:user) { create(:user) }
    let(:event) { create(:event) }

    it 'is false before joining' do
      expect(user.attending?(event)).to be(false)
    end

    it 'is true after joining' do
      create(:event_attendance, event: event, attendee: user)

      expect(user.reload.attending?(event)).to be(true)
    end
  end

  describe 'destroying a user' do
    # `organized_events` used to be `dependent: :nullify`, which could not work:
    # events.organizer_id is NOT NULL.
    it 'removes the events they organised instead of orphaning them' do
      user = create(:user)
      create(:event, organizer: user)

      expect { user.destroy! }.to change(Event, :count).by(-1)
    end
  end
end
