# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Health', type: :request do
  it 'reports ok without authentication' do
    get '/health'

    expect(response).to have_http_status(:ok)
    expect(json_body).to eq('status' => 'ok', 'database' => 'ok')
  end

  it 'reports 503 when the database cannot be reached' do
    allow(ActiveRecord::Base).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished)

    get '/health'

    expect(response).to have_http_status(:service_unavailable)
    expect(json_body['status']).to eq('error')
  end
end
