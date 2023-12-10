# frozen_string_literal: true

# An event someone is organising. `date` is the moment the event starts
# (a `datetime` column, stored in UTC).
class Event < ApplicationRecord
  NAME_MAX_LENGTH = 25
  DESCRIPTION_MAX_LENGTH = 2_000

  ## Associations ##
  has_many :event_attendances, dependent: :destroy
  has_many :attendees, through: :event_attendances

  belongs_to :organizer, class_name: 'User'

  ## Validations ##
  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }, uniqueness: true
  validates :date, presence: true
  validates :location, presence: true
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }

  ## Scopes ##
  scope :upcoming, -> { where(arel_table[:date].gteq(Time.current)) }
  scope :chronological, -> { order(date: :asc, id: :asc) }

  # Eager-loads everything the API serialiser touches, so a list of N events
  # costs three queries instead of 1 + 2N.
  scope :for_listing, -> { includes(:organizer).with_attendee_counts }
  scope :with_attendee_counts, lambda {
    left_joins(:event_attendances)
      .select(arel_table[Arel.star], EventAttendance.arel_table[:id].count.as('attendees_count'))
      .group(arel_table[:id])
  }

  # True when `user` organises this event. The only person allowed to change
  # or delete it — see EventPolicy.
  def organized_by?(user)
    user.present? && organizer_id == user.id
  end

  # Reads the grouped count when the record came from `with_attendee_counts`,
  # and falls back to a direct count otherwise.
  def attendees_count
    self[:attendees_count] || event_attendances.count
  end
end
