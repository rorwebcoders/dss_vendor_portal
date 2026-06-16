class CreateServiceCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :service_codes do |t|
      t.string :shipstation_service_code
      t.string :shipstation_name
      t.boolean :domestic
      t.boolean :international
      t.references :carrier, null: false, foreign_key: true
      t.timestamps
    end
    add_index :service_codes, :shipstation_service_code, unique: true
  end
end
