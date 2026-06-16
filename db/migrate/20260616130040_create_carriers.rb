class CreateCarriers < ActiveRecord::Migration[8.0]
  def change
    create_table :carriers do |t|
      t.string :shipstation_carrier_id, null: false
      t.string :shipstation_carrier_code
      t.string :shipstation_friendly_name
      t.string :shipstation_account_number
      t.boolean :enabled, default: true
      t.timestamps
    end
    add_index :carriers, :shipstation_carrier_id, unique: true
  end
end
