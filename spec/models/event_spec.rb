# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:event_attendances).dependent(:destroy) }
    it { is_expected.to have_many(:attendees).through(:event_attendances) }
    it { is_expected.to belong_to(:organizer).class_name('User') }
  end

  describe 'validations' do
    subject { build(:event) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(Event::NAME_MAX_LENGTH) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:location) }
    it { is_expected.to validate_length_of(:description).is_at_most(Event::DESCRIPTION_MAX_LENGTH) }
  end

  describe '#organized_by?' do
    let(:organizer) { create(:user) }
    let(:event) { create(:event, organizer: organizer) }

    it 'is true for the organizer' do
      expect(event.organized_by?(organizer)).to be(true)
    end

    it 'is false for anybody else' do
      expect(event.organized_by?(create(:user))).to be(false)
    end

    it 'is false for a signed-out visitor' do
      expect(event.organized_by?(nil)).to be(false)
    end
  end

  describe '#attendees_count' do
    let(:event) { create(:event) }

    before { create_list(:event_attendance, 3, event: event) }

    it 'counts the attendances when loaded on its own' do
      expect(event.attendees_count).to eq(3)
    end

    it 'reads the grouped count without a second query when loaded via .with_attendee_counts' do
      loaded = described_class.with_attendee_counts.find_by(id: event.id)

      expect(loaded.attendees_count).to eq(3)
      expect(count_queries { loaded.attendees_count }).to be_empty
    end
  end

  describe '.upcoming' do
    it 'excludes events whose start time has passed' do
      future = create(:event)
      create(:event, :past)

      expect(described_class.upcoming).to contain_exactly(future)
    end
  end

  describe '.chronological' do
    it 'orders by start time ascending' do
      later = create(:event, date: 3.weeks.from_now)
      sooner = create(:event, date: 1.week.from_now)

      expect(described_class.chronological.to_a).to eq([sooner, later])
    end
  end
end
