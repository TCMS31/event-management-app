# frozen_string_literal: true

class CreateEventAttendances < ActiveRecord::Migration[7.0]
  def change
    create_table :event_attendances do |t|
      t.belongs_to :attendee, class: :User, null: false, index: false
      t.belongs_to :event, null: false, index: false

      t.index %i[event_id attendee_id], unique: true, name: 'idx_event_attendee'

      t.timestamps
    end
  end
end
