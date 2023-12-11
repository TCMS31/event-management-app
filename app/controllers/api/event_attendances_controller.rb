# frozen_string_literal: true

module Api
  class EventAttendancesController < ApplicationController
    include RenderJsonResponse

    before_action :authenticate_user!
    before_action :set_event, only: :create

    def create
      @event.attendees << current_user
      @event.errors.empty? ? success_render(@event) : error_render(@event)
    end

    private

    def set_event
      @event = Event.find_by(id: params[:id])

      head :not_found if @event.blank?
    end
  end
end
