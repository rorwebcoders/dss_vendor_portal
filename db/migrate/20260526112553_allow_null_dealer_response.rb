class AllowNullDealerResponse < ActiveRecord::Migration[8.0]
  def change
    change_column_null :purchase_orders, :dealer_response, true
  end
end
