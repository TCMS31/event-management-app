# frozen_string_literal: true

Rails.application.routes.draw do
  get '/health', to: 'health#show'

  devise_for :users
  namespace :api, defaults: { format: :json } do
    resources :events, except: %i[new edit] do
      member { post :join, controller: :event_attendances, action: :create }
    end
  end

  resources :events, only: :index
  root action: :index, controller: 'events'
end
