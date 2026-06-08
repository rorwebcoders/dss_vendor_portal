class CreateRejectedOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :rejected_orders do |t|
      t.string :purchase_order_id
      t.string :dealer_id
      t.string :user_id
      t.string :po_number
      t.datetime :rejected_at
      t.integer :status
      t.json :purchase_order_data
      t.json :line_items_data
      t.timestamps
    end
  end
end
