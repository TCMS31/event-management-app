require "rails_helper"

class UserTest < ActiveSupport::TestCase
  RSpec.describe User, type: :model do
    describe 'associations' do
      it { should have_many(:organized_events).class_name('Event').with_foreign_key('organizer_id') }
      it { should have_many(:event_attendances).dependent(:destroy) }
      it { should have_many(:attended_events).through(:event_attendances).source(:event) }
    end
  end
end
