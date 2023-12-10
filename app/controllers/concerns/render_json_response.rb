# frozen_string_literal: true

# Shared JSON rendering helpers for the API controllers.
module RenderJsonResponse
  extend ActiveSupport::Concern

  def success_render(object, status: :ok)
    render json: object, status: status
  end

  def error_render(errors, status: :unprocessable_content)
    messages = errors.respond_to?(:messages) ? errors.messages : errors
    render json: messages, status: status
  end

  # Renders an ApplicationService::Result, whichever way it went.
  def render_result(result)
    if result.success?
      success_render(result.payload,
                     status: result.status)
    else
      error_render(result.error, status: result.status)
    end
  end
end
