# frozen_string_literal: true

class Event < ApplicationRecord
  ## Associations ##
  has_many :event_attendances, dependent: :destroy
  has_many :attendees, through: :event_attendances

  belongs_to :organizer, class_name: :User

  ## Validations ##
  validates :name, presence: true, length: { maximum: 25 }, uniqueness: true
end
