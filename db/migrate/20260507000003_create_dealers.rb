# frozen_string_literal: true

class CreateDealers < ActiveRecord::Migration[8.0]
  def change
    create_table :dealers do |t|
      t.string :name, null: false
      t.string :abbreviation, null: false
      t.string :api_name
      t.string :api_location_code
      t.text :email
      t.string :dealer_name
      t.string :dealer_address1
      t.string :dealer_city
      t.string :dealer_state
      t.string :dealer_zip
      t.string :dealer_country
      t.boolean :enabled, null: false, default: true
      t.timestamps null: false
    end

    add_index :dealers, :abbreviation
    add_index :dealers, :enabled
  end
end
