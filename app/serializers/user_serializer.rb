# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  # Deliberately minimal: an organizer's record is public to every signed-in
  # user, so only the fields the UI needs are exposed.
  attributes :id, :email
end
