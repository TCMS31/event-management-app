# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable

  ## Associations ##
  has_many :organized_events, class_name: 'Event', foreign_key: :organizer_id,
                              dependent: :destroy, inverse_of: :organizer
  has_many :event_attendances, foreign_key: :attendee_id, dependent: :destroy, inverse_of: :attendee
  has_many :attended_events, through: :event_attendances, source: :event

  # True when this user has already joined `event`.
  def attending?(event)
    event_attendances.exists?(event_id: event.id)
  end
end
