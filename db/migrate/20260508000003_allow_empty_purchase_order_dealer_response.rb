# frozen_string_literal: true

class AllowEmptyPurchaseOrderDealerResponse < ActiveRecord::Migration[8.0]
  def up
    change_column_null :purchase_orders, :dealer_response, true
    change_column_default :purchase_orders, :dealer_response, from: "pending", to: nil
    execute <<~SQL.squish
      UPDATE purchase_orders
      SET dealer_id = NULL, dealer_response = NULL
      WHERE dealer_id IS NULL OR dealer_response = 'rejected'
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE purchase_orders
      SET dealer_response = 'pending'
      WHERE dealer_response IS NULL
    SQL
    change_column_default :purchase_orders, :dealer_response, from: nil, to: "pending"
    change_column_null :purchase_orders, :dealer_response, false
  end
end
