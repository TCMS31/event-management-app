# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventAttendance, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:attendee).class_name('User') }
    it { is_expected.to belong_to(:event) }
  end

  describe 'validations' do
    subject { create(:event_attendance) }

    it { is_expected.to validate_uniqueness_of(:event_id).scoped_to(:attendee_id) }
  end

  it 'is rejected by the database as well as the model' do
    attendance = create(:event_attendance)
    duplicate = described_class.new(event: attendance.event, attendee: attendance.attendee)

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
