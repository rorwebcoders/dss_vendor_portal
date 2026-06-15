class AddShipstationShipmentIdToPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_orders, :shipstation_shipment_id, :string
  end
end
