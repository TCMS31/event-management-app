# frozen_string_literal: true

# `event_attendances` was created with `index: false` on both references and no
# foreign keys at all, which left three problems:
#
#   * nothing at the database level stopped an attendance row pointing at a
#     deleted user or a deleted event;
#   * "which events has this user joined?" had no usable index — the only index
#     is on (event_id, attendee_id), and attendee_id is not its leading column;
#   * listing upcoming events in date order was a sequential scan plus a sort.
class AddEventAttendanceConstraintsAndIndexes < ActiveRecord::Migration[7.0]
  def change
    # Clear any pre-existing orphans so the foreign keys can be added.
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          DELETE FROM event_attendances
          WHERE attendee_id NOT IN (SELECT id FROM users)
             OR event_id NOT IN (SELECT id FROM events)
        SQL
      end
    end

    add_index :event_attendances, :attendee_id, if_not_exists: true
    add_index :events, :date, if_not_exists: true

    add_foreign_key :event_attendances, :users, column: :attendee_id, on_delete: :cascade
    add_foreign_key :event_attendances, :events, on_delete: :cascade
  end
end
