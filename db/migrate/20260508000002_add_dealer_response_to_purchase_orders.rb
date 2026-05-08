# frozen_string_literal: true

class AddDealerResponseToPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_orders, :dealer_response, :string, null: false, default: "pending"
    add_index :purchase_orders, :dealer_response
  end
end
