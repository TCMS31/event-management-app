require "rails_helper"

class EventTest < ActiveSupport::TestCase
  RSpec.describe Event, type: :model do
    describe 'associations' do
      it { should have_many(:event_attendances).dependent(:destroy) }
      it { should have_many(:attendees).through(:event_attendances) }
      it { should belong_to(:organizer).class_name('User') }
    end

    describe 'validations' do
      let!(:event) { create(:event) }

      it { should validate_presence_of(:name) }
      it { should validate_length_of(:name).is_at_most(25) }
      it { should validate_uniqueness_of(:name) }
      it { should allow_value('Valid Name').for(:name) }
    end
  end
end
