# frozen_string_literal: true

# Join record between a User (the attendee) and an Event.
class EventAttendance < ApplicationRecord
  ## Associations ##
  belongs_to :attendee, class_name: 'User'
  belongs_to :event

  ## Validations ##
  # Backed by a unique index on (event_id, attendee_id); the validation gives a
  # friendly message, the index closes the race.
  validates :event_id, uniqueness: { scope: %i[attendee_id] }
end
