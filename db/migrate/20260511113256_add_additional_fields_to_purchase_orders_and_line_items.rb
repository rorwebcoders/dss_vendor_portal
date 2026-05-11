class AddAdditionalFieldsToPurchaseOrdersAndLineItems < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_orders, :skuvault_status, :string
    add_column :purchase_orders, :payment_status, :string
    add_column :purchase_orders, :supplier_name, :string
    add_column :purchase_orders, :status, :integer, default: 0

    add_column :line_items, :skuvault_product_id, :string
    add_column :line_items, :received_quantity, :string
    add_column :line_items, :received_date, :string
    add_column :line_items, :retail_cost, :string
    add_column :line_items, :public_notes, :text
    add_column :line_items, :private_notes, :text
  end
end
