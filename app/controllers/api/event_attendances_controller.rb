# frozen_string_literal: true

module Api
  class EventAttendancesController < BaseController
    before_action :set_event, only: :create

    # POST /api/events/:id/join
    def create
      render_result(Events::Join.call(event: @event, user: current_user))
    end
  end
end
