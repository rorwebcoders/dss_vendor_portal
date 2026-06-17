class AddShipstationStoreIdToPo < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_orders, :shipstation_store_id, :string
  end
end
