# frozen_string_literal: true

# Serves the single HTML page. All data on it is fetched from /api/events by the
# `events` Stimulus controller, so there is nothing to do here but authenticate.
class EventsController < ApplicationController
  before_action :authenticate_user!

  def index; end
end
