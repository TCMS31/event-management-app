# frozen_string_literal: true

class EventSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :date, :location, :organizer

  def date
    object.date.strftime('%Y-%m-%d')
  end
end
