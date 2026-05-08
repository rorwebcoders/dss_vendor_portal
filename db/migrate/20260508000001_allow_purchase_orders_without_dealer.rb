# frozen_string_literal: true

class AllowPurchaseOrdersWithoutDealer < ActiveRecord::Migration[8.0]
  def change
    change_column_null :purchase_orders, :dealer_id, true
  end
end
