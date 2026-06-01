class AddAdditionalFieldsToDealerAndPo < ActiveRecord::Migration[8.0]
  def change
    add_column :dealers, :sm_dealer_id, :integer
    add_column :purchase_orders, :tracking_number, :string
    add_column :purchase_orders, :shipstation_label_url, :string
  end
end
