# frozen_string_literal: true

module Events
  # Adds a user to an event's attendee list.
  #
  # Joining twice is *not* an error worth a 500: the database unique index and
  # the model validation both guard it, and this service turns either outcome
  # into a plain 409 the client can act on.
  class Join < ApplicationService
    def initialize(event:, user:)
      @event = event
      @user = user
      super()
    end

    def call
      return failure({ base: ['You cannot join this event'] }, status: :forbidden) unless policy.join?

      attendance = EventAttendance.new(event: @event, attendee: @user)
      return failure(attendance.errors.messages, status: :conflict) unless attendance.save

      EventNotifier.attendee_joined(event: @event, attendee: @user)
      success(@event.reload)
    rescue ActiveRecord::RecordNotUnique
      # Lost a race with a concurrent request for the same (event, user).
      failure({ event: ['has already been taken'] }, status: :conflict)
    end

    private

    def policy = @policy ||= EventPolicy.new(@user, @event)
  end
end
