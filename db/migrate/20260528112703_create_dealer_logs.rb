class CreateDealerLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :dealer_logs do |t|
      t.string :purchase_order_id
      t.string :dealer_id
      t.datetime :rejected_at
      t.integer :status
      t.timestamps
    end
  end
end
