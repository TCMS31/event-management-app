# frozen_string_literal: true

module Api
  class EventsController < ApplicationController
    include RenderJsonResponse

    before_action :authenticate_user!
    before_action :set_event, only: [:show, :update, :destroy]

    def index
      render json: Event.includes(:organizer).all
    end

    def show
      render json: @event
    end

    def create
      @event = current_user.organized_events.build(event_params)
      @event.save ? success_render(@event) : error_render(@event)
    end

    def update
      @event.update(event_params) ? success_render(@event) : error_render(@event)
    end

    def destroy
      @event.destroy
      head :no_content
    end

    private

    def set_event
      @event = Event.find_by(id: params[:id])

      head :not_found if @event.blank?
    end

    def event_params
      params.require(:event).permit(:name, :description, :date, :location, :organizer)
    end
  end
end
