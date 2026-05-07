# frozen_string_literal: true

class CreateDealers < ActiveRecord::Migration[8.0]
  def change
    create_table :dealers do |t|
      t.string :name, null: false
      t.string :abbreviation, null: false
      t.string :api_name
      t.string :api_location_code
      t.text :email
      t.boolean :enabled, null: false, default: true
      t.timestamps null: false
    end

    add_index :dealers, :abbreviation
    add_index :dealers, :enabled
  end
end
