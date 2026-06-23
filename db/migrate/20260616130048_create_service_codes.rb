class CreateServiceCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :service_codes do |t|
      t.string :shipstation_service_code
      t.string :shipstation_name
      t.boolean :domestic
      t.boolean :international
      t.boolean :enabled, default: true, null: false
      t.references :carrier, null: false, foreign_key: true
      t.timestamps
    end
    add_index :service_codes, [:carrier_id, :shipstation_service_code], unique: true
    add_index :service_codes, :enabled
  end
end
