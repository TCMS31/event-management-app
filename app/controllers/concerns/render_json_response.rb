# frozen_string_literal: true

module RenderJsonResponse
  extend ActiveSupport::Concern

  def success_render(object)
    render json: object
  end

  def error_render(object)
    render json: object&.errors&.messages, status: :unprocessable_entity
  end
end
