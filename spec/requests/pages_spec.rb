# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HTML pages', type: :request do
  let(:user) { create(:user, password: 'correct-horse') }

  describe 'GET /' do
    it 'sends a signed-out visitor to the login page' do
      get '/'

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'renders the events page for a signed-in user' do
      sign_in user
      get '/'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="events"', user.email)
    end
  end

  describe 'logging in' do
    it 'says why a failed login was refused' do
      post user_session_path, params: { user: { email: user.email, password: 'wrong' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Invalid email or password.')
    end

    it 'confirms a successful login on the next page' do
      post user_session_path, params: { user: { email: user.email, password: 'correct-horse' } }
      follow_redirect!

      expect(response.body).to include('Signed in successfully.')
    end
  end
end
