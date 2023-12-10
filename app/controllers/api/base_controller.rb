# frozen_string_literal: true

module Api
  # Everything under /api shares this: JSON in, JSON out, signed-in only,
  # and no HTML error pages leaking out of a fetch() call.
  class BaseController < ApplicationController
    include RenderJsonResponse

    # The API is called from fetch(), which sends the CSRF token in a header.
    protect_from_forgery with: :exception

    before_action :authenticate_user!

    # Serializers are handed a Viewer, not the raw user, so per-row questions
    # like "have I joined this?" resolve from one preloaded set.
    serialization_scope :viewer

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: 'Not found' }, status: :not_found
    end

    private

    def viewer
      @viewer ||= Viewer.new(current_user)
    end

    # Loads the event named by :id or halts with 404.
    def set_event
      @event = Event.find(params[:id])
    end

    # Halts with 403 unless the policy allows `action`.
    def authorize_event!(action)
      return if EventPolicy.new(current_user, @event).public_send(action)

      render json: { error: 'You are not allowed to do that' }, status: :forbidden
    end
  end
end
