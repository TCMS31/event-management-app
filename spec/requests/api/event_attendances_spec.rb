require 'rails_helper'

RSpec.describe "Api::EventAttendances", type: :request do
  describe 'POST #create' do
    let(:user) { create(:user) }
    let(:event) { create(:event) }

    before { sign_in(user) }

    context 'when authentication is successful' do
      before { post "/api/events/#{event.id}/join" }

      it 'adds the current user to the event attendees' do
        event.reload
        expect(event.attendees).to include(user)
      end

      it 'renders a successful response with the event JSON' do
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to include('id', 'name')
      end
    end

    context 'when authentication fails' do
      before { sign_out(user) }

      it 'does not add the current user to the event attendees' do
        post "/api/events/#{event.id}/join"
        event.reload

        expect(event.attendees).not_to include(user)
      end

      it 'renders an unauthorized response' do
        post "/api/events/#{event.id}/join"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when event is not found' do
      it 'renders a not found response' do
        post "/api/events/#{100000}/join"
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
