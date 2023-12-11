require "rails_helper"

class EventTest < ActiveSupport::TestCase
  RSpec.describe EventAttendance, type: :model do
    describe 'associations' do
      it { should belong_to(:attendee).class_name('User') }
      it { should belong_to(:event) }
    end

    describe 'validations' do
      subject { create(:event_attendance) }

      it { should validate_uniqueness_of(:event_id).scoped_to(:attendee_id) }
    end
  end
end
