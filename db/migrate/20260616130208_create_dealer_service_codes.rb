class CreateDealerServiceCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :dealer_service_codes do |t|
      t.references :dealer, null: false, foreign_key: true
      t.references :service_code, null: false, foreign_key: true
      t.timestamps
    end
    add_index :dealer_service_codes, [:dealer_id, :service_code_id], unique: true
  end
end
