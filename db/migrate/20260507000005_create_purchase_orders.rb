# frozen_string_literal: true

class CreatePurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_orders do |t|
      t.references :dealer, null: true, foreign_key: true
      t.integer :po_id
      t.string :po_number
      t.string :skuvault_status
      t.string :shipping_name
      t.string :shipping_address1
      t.string :shipping_city
      t.string :shipping_state
      t.string :shipping_zip
      t.string :shipping_country
      t.string :skuvault_id
      t.string :skuvault_marketplace_id
      t.string :skuvault_channel_id
      t.string :shipping_firstname
      t.string :shipping_lastname
      t.string :shipping_company
      t.string :shipping_phone
      t.string :shipping_email
      t.string :tracking_number
      t.string :shipstation_label_url
      t.string :weight
      t.string :units
      t.string :length
      t.string :width
      t.string :height
      t.json :notified_sm_request
      t.json :read_to_ship_response
      t.json :others_response
      t.integer :status, default: 0
      t.integer :dealer_response, default: 0
      t.timestamps null: false
    end
    add_index :purchase_orders, :po_number
    add_index :purchase_orders, :dealer_response
  end
end
