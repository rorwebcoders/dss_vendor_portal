# frozen_string_literal: true

class CreatePurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_orders do |t|
      t.references :dealer, null: false, foreign_key: true
      t.integer :po_id
      t.string :po_number, null: false
      t.string :po_type
      t.timestamps null: false
    end

    add_index :purchase_orders, :po_id
    add_index :purchase_orders, :po_number
  end
end
