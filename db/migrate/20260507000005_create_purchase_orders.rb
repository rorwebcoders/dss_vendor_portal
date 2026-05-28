# frozen_string_literal: true

class CreatePurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_orders do |t|
      t.references :dealer, null: true, foreign_key: true
      t.integer :po_id
      t.string :po_number, null: false
      t.string :po_type
      t.string :skuvault_status
      t.string :payment_status
      t.string :supplier_name
      t.json :notified_sm_request
      t.string :shipping_name
      t.string :shipping_address1
      t.string :shipping_city
      t.string :shipping_state
      t.string :shipping_zip
      t.string :shipping_country
      t.string :weight
      t.string :units
      t.string :length
      t.string :width
      t.string :height
      t.integer :status, default: 0
      t.integer :dealer_response, default: 0
      t.timestamps null: false
    end

    add_index :purchase_orders, :po_id
    add_index :purchase_orders, :po_number
    add_index :purchase_orders, :dealer_response
  end
end
