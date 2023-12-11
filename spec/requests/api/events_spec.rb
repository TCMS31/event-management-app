require 'rails_helper'

RSpec.describe "Api::Events", type: :request do
  let(:event) { create(:event) }
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /api/events" do
    context "when user is not authenticated" do
      before do
        sign_out user
        get '/api/events'
      end

      it "returns status code 401 (Unauthorized)" do
        expect(response).to have_http_status(401)
      end
    end

    context "when user is authenticated" do
      before do
        create_list(:event, 10)
        get '/api/events'
      end

      it 'returns all events' do
        expect(response.parsed_body.size).to eq(10)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /api/events/:id" do
    context "when the event does not exist" do
      before { get "/api/events/non_existent_id" }

      it "returns status code 404" do
        expect(response).to have_http_status(404)
      end
    end

    context "when the event exists" do
      before { get "/api/events/#{event.id}" }

      it "returns a single event" do
        expect(JSON.parse(response.body)["name"]).to eq(event.name)
      end

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end
    end
  end

  describe "POST /api/events" do
    context "when event data is invalid" do
      before do
        post "/api/events", params: { event: { name: nil } }
      end

      it "returns status code 422 (Unprocessable Entity)" do
        expect(response).to have_http_status(422)
      end

      it "returns error messages in the response body" do
        expect(JSON.parse(response.body)['name']).to include("can't be blank")
      end
    end

    context "when event data is valid" do
      let(:event_attributes) { attributes_for(:event) }

      before do
        post "/api/events", params: { event: event_attributes }
      end

      it "creates a new event" do
        expect(Event.last.name).to eq(event_attributes[:name])
      end

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end
    end
  end

  describe "PUT /api/events/:id" do
    context "when event data is invalid" do
      before do
        put "/api/events/#{event.id}", params: { event: { name: nil } }
      end

      it "returns status code 422 (Unprocessable Entity)" do
        expect(response).to have_http_status(422)
      end

      it "returns error messages in the response body" do
        expect(JSON.parse(response.body)['name']).to include("can't be blank")
      end
    end

    context "when the event exists" do
      before { put "/api/events/#{event.id}", params: { event: { name: "Updated Event Name" } } }

      it "updates an existing event" do
        expect(Event.find(event.id).name).to eq("Updated Event Name")
      end

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end
    end
  end

  describe "DELETE /api/events/:id" do
    context "when the event does not exist" do
      before { delete "/api/events/non_existent_id" }

      it "returns status code 404" do
        expect(response).to have_http_status(404)
      end
    end

    context "when the event exists" do
      before { delete "/api/events/#{event.id}" }

      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end
    end
  end
end
