# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventPolicy do
  let(:organizer) { create(:user) }
  let(:stranger)  { create(:user) }
  let(:event)     { create(:event, organizer: organizer) }

  describe '#show?' do
    it 'allows any signed-in user' do
      expect(described_class.new(stranger, event).show?).to be(true)
    end

    it 'denies a signed-out visitor' do
      expect(described_class.new(nil, event).show?).to be(false)
    end
  end

  describe '#update? / #destroy?' do
    it 'allows the organizer' do
      policy = described_class.new(organizer, event)

      expect(policy.update?).to be(true)
      expect(policy.destroy?).to be(true)
    end

    it 'denies everybody else' do
      policy = described_class.new(stranger, event)

      expect(policy.update?).to be(false)
      expect(policy.destroy?).to be(false)
    end

    it 'denies a signed-out visitor' do
      expect(described_class.new(nil, event).update?).to be(false)
    end
  end

  describe '#join?' do
    it 'allows a signed-in user who is not the organizer' do
      expect(described_class.new(stranger, event).join?).to be(true)
    end

    it 'denies the organizer' do
      expect(described_class.new(organizer, event).join?).to be(false)
    end

    it 'still allows a user who already joined — the duplicate is a conflict, not a permission problem' do
      create(:event_attendance, event: event, attendee: stranger)

      expect(described_class.new(stranger.reload, event).join?).to be(true)
    end

    it 'denies a signed-out visitor' do
      expect(described_class.new(nil, event).join?).to be(false)
    end
  end
end
