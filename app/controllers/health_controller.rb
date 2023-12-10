# frozen_string_literal: true

# Liveness/readiness endpoint for the container healthcheck and any load balancer.
# Deliberately unauthenticated and free of side effects.
class HealthController < ApplicationController
  def show
    ActiveRecord::Base.connection.execute('SELECT 1')
    render json: { status: 'ok', database: 'ok' }
  rescue StandardError => e
    Rails.logger.error("[health] #{e.class}: #{e.message}")
    render json: { status: 'error', database: 'unavailable' }, status: :service_unavailable
  end
end
