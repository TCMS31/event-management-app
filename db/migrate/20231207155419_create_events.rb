# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string :name, null: false, index: { unique: true }, limit: 25
      t.text :description
      t.datetime :date
      t.string :location

      t.references :organizer, null:false, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
