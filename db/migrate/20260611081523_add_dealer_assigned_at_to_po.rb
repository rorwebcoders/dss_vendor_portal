class AddDealerAssignedAtToPo < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_orders, :dealer_assigned_at, :datetime
    add_column :purchase_orders, :shipstation_id, :string
  end
end
