# frozen_string_literal: true

# Per-request view of "who is asking". Handed to the serializers as their
# scope so that a list of N events costs one extra query for attendance,
# not N — the previous shape would have called `attending?` per row.
class Viewer
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def signed_in? = user.present?

  def joined?(event)
    return false if user.blank?

    joined_event_ids.include?(event.id)
  end

  def organizer_of?(event)
    event.organized_by?(user)
  end

  private

  def joined_event_ids
    @joined_event_ids ||= Set.new(user.event_attendances.pluck(:event_id))
  end
end
