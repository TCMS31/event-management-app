# frozen_string_literal: true

module Api
  class EventsController < BaseController
    before_action :set_event, only: %i[show update destroy]
    before_action -> { authorize_event!(:update?) }, only: %i[update destroy]

    # GET /api/events
    # Paginated so a large catalogue cannot be pulled into memory in one request.
    def index
      scope = Event.for_listing.chronological
      render json: Pagination.apply(scope, params: params),
             meta: Pagination.meta(Event.all, params: params),
             root: :events
    end

    # GET /api/events/:id
    def show
      success_render(@event)
    end

    # POST /api/events
    def create
      event = current_user.organized_events.build(event_params)
      event.save ? success_render(event, status: :created) : error_render(event.errors)
    end

    # PATCH/PUT /api/events/:id
    def update
      @event.update(event_params) ? success_render(@event) : error_render(@event.errors)
    end

    # DELETE /api/events/:id
    def destroy
      @event.destroy
      head :no_content
    end

    private

    # `organizer` is deliberately not permitted: ownership comes from the
    # session, never from the request body.
    def event_params
      params.expect(event: %i[name description date location])
    end
  end
end
