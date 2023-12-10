# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::EventAttendances', type: :request do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  describe 'POST /api/events/:id/join' do
    context 'when signed in' do
      before { sign_in(user) }

      it 'adds the current user to the attendees' do
        expect { post "/api/events/#{event.id}/join" }
          .to change { event.reload.attendees.include?(user) }.from(false).to(true)
      end

      it 'renders the event' do
        post "/api/events/#{event.id}/join"

        expect(response).to have_http_status(:ok)
        expect(json_event).to include('id' => event.id, 'name' => event.name)
      end

      it 'marks the event as joined in the payload' do
        post "/api/events/#{event.id}/join"

        expect(json_event['joined']).to be(true)
      end

      it 'returns 409 rather than a 500 when joining twice' do
        # The original controller let ActiveRecord::RecordInvalid escape, so the
        # second click on Join returned a 500 error page.
        post "/api/events/#{event.id}/join"
        expect(response).to have_http_status(:ok)

        expect { post "/api/events/#{event.id}/join" }.not_to change(EventAttendance, :count)
        expect(response).to have_http_status(:conflict)
      end

      it 'refuses to let an organizer join their own event' do
        own = create(:event, organizer: user)

        post "/api/events/#{own.id}/join"

        expect(response).to have_http_status(:forbidden)
        expect(own.reload.attendees).to be_empty
      end

      it 'returns 404 for an event that does not exist' do
        post '/api/events/100000/join'

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when signed out' do
      it 'returns 401 and does not record an attendance' do
        expect { post "/api/events/#{event.id}/join" }.not_to change(EventAttendance, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
