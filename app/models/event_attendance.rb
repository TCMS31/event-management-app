# frozen_string_literal: true

class EventAttendance < ApplicationRecord
  ## Associations ##
  belongs_to :attendee, class_name: :User
  belongs_to :event

  ## Validations ##
  validates :event_id, uniqueness: { scope: %i[attendee_id] }
end
