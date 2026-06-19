# frozen_string_literal: true

class CreateDealers < ActiveRecord::Migration[8.0]
  def change
    create_table :dealers do |t|
      t.integer :sm_dealer_id
      t.string :abbreviation, null: false
      t.string :dealer_name, null: false
      t.string :dealer_address
      t.string :address_line1
      t.string :address_line2
      t.string :address_line3
      t.string :city_locality
      t.string :state_province
      t.string :postal_code
      t.string :country_code
      t.string :dealership_name
      t.string :phone
      t.json :shipstation_service_codes
      t.string :shipstation_warehouse_id
      t.text :shipstation_request
      t.text :shipstation_response
      t.boolean :enabled, null: false, default: true
      t.timestamps null: false
    end
    add_index :dealers, :sm_dealer_id
    add_index :dealers, :abbreviation
    add_index :dealers, :enabled
  end
end
