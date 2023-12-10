# frozen_string_literal: true

# Single place that answers "is this user allowed to do that to this event?".
# Controllers ask the policy; they never re-derive the rule themselves.
class EventPolicy
  attr_reader :user, :event

  def initialize(user, event)
    @user = user
    @event = event
  end

  # Anyone signed in can read the catalogue.
  def show? = user.present?

  # Only the organizer may change or remove their own event.
  def update? = event.organized_by?(user)
  def destroy? = update?

  # You may join any event you do not organise. Having already joined is a
  # conflict rather than a permission problem, so it is handled in Events::Join.
  def join?
    user.present? && !event.organized_by?(user)
  end
end
