# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Events', type: :request do
  let(:user) { create(:user) }
  let!(:event) { create(:event, organizer: user) }

  before { sign_in user }

  describe 'GET /api/events' do
    context 'when the user is not authenticated' do
      before do
        sign_out user
        get '/api/events'
      end

      it 'returns 401' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the user is authenticated' do
      before do
        create_list(:event, 4)
        get '/api/events'
      end

      it 'returns 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns every event under the events root' do
        expect(json_events.size).to eq(5)
      end

      it 'reports pagination metadata' do
        expect(json_meta).to include('page' => 1, 'total_count' => 5, 'total_pages' => 1)
      end

      it 'orders events by start time' do
        dates = json_events.map { |e| Time.zone.parse(e['date']) }

        expect(dates).to eq(dates.sort)
      end
    end

    describe 'pagination' do
      before { create_list(:event, 12) }

      it 'returns at most one page at a time' do
        get '/api/events', params: { per_page: 5 }

        expect(json_events.size).to eq(5)
        expect(json_meta).to include('page' => 1, 'per_page' => 5, 'total_count' => 13, 'total_pages' => 3)
      end

      it 'returns the requested page' do
        get '/api/events', params: { per_page: 5, page: 3 }

        expect(json_events.size).to eq(3)
        expect(json_meta['page']).to eq(3)
      end

      it 'caps an oversized per_page instead of returning everything' do
        get '/api/events', params: { per_page: 10_000 }

        expect(json_meta['per_page']).to eq(Pagination.max_per_page)
      end

      it 'does not go back to the database once per row' do
        queries = count_queries { get '/api/events', params: { per_page: 10 } }

        expect(json_events.size).to eq(10)
        # events + organizers + the viewer's attendance set + the count, and
        # the Devise session lookup. Well under one query per row either way.
        expect(queries.size).to be <= 6
      end
    end

    it 'never exposes anything but id and email for the organizer' do
      get '/api/events'

      expect(json_events.first['organizer'].keys).to contain_exactly('id', 'email')
    end
  end

  describe 'GET /api/events/:id' do
    it 'returns 404 for an id that does not exist' do
      get '/api/events/non_existent_id'

      expect(response).to have_http_status(:not_found)
    end

    it 'returns the event' do
      get "/api/events/#{event.id}"

      expect(response).to have_http_status(:ok)
      expect(json_event).to include('id' => event.id, 'name' => event.name)
    end

    it 'serialises the start time in full, not just the calendar day' do
      event.update!(date: Time.utc(2026, 12, 31, 18, 30))

      get "/api/events/#{event.id}"

      expect(json_event['date']).to eq('2026-12-31T18:30:00Z')
    end

    it 'does not blow up when an event has no start time' do
      # `date` is nullable at the database level; the old serializer called
      # strftime on nil and returned a 500 for the whole list.
      event.update_column(:date, nil)

      get "/api/events/#{event.id}"

      expect(response).to have_http_status(:ok)
      expect(json_event['date']).to be_nil
    end

    it 'reports the attendee count' do
      create_list(:event_attendance, 2, event: event)

      get "/api/events/#{event.id}"

      expect(json_event['attendees_count']).to eq(2)
    end
  end

  describe 'POST /api/events' do
    it 'returns 422 and the messages when the data is invalid' do
      post '/api/events', params: { event: { name: nil } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body['name']).to include("can't be blank")
    end

    it 'rejects an event with no start time' do
      post '/api/events', params: { event: attributes_for(:event).merge(date: nil) }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body['date']).to include("can't be blank")
    end

    it 'creates the event and returns 201' do
      attributes = attributes_for(:event)

      expect { post '/api/events', params: { event: attributes } }.to change(Event, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(Event.last.name).to eq(attributes[:name])
    end

    it 'takes the organizer from the session, not the request body' do
      impostor = create(:user)

      post '/api/events', params: { event: attributes_for(:event).merge(organizer_id: impostor.id) }

      expect(Event.last.organizer).to eq(user)
    end
  end

  describe 'PUT /api/events/:id' do
    it 'returns 422 when the data is invalid' do
      put "/api/events/#{event.id}", params: { event: { name: nil } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body['name']).to include("can't be blank")
    end

    it 'updates an event the user organises' do
      put "/api/events/#{event.id}", params: { event: { name: 'Updated Event Name' } }

      expect(response).to have_http_status(:ok)
      expect(event.reload.name).to eq('Updated Event Name')
    end

    it 'refuses to update somebody else\'s event' do
      other = create(:event)

      put "/api/events/#{other.id}", params: { event: { name: 'Hijacked' } }

      expect(response).to have_http_status(:forbidden)
      expect(other.reload.name).not_to eq('Hijacked')
    end
  end

  describe 'DELETE /api/events/:id' do
    it 'returns 404 for an id that does not exist' do
      delete '/api/events/non_existent_id'

      expect(response).to have_http_status(:not_found)
    end

    it 'deletes an event the user organises' do
      expect { delete "/api/events/#{event.id}" }.to change(Event, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'refuses to delete somebody else\'s event' do
      other = create(:event)

      expect { delete "/api/events/#{other.id}" }.not_to change(Event, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
