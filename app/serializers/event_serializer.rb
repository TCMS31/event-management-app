# frozen_string_literal: true

class EventSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :location, :date, :attendees_count, :editable, :joined

  belongs_to :organizer, serializer: UserSerializer

  # ISO 8601 including the time of day. The column is a `datetime`, and the
  # previous `strftime('%Y-%m-%d')` both discarded the start time and raised
  # NoMethodError whenever `date` was nil.
  def date
    object.date&.iso8601
  end

  delegate :attendees_count, to: :object

  # Lets the UI render only the actions this viewer may actually perform,
  # instead of showing Delete on every row and finding out server-side.
  def editable
    viewer.organizer_of?(object)
  end

  def joined
    viewer.joined?(object)
  end

  private

  def viewer
    scope.is_a?(Viewer) ? scope : Viewer.new(scope)
  end
end
