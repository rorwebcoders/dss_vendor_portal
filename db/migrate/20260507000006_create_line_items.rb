# frozen_string_literal: true

class CreateLineItems < ActiveRecord::Migration[8.0]
  def change
    create_table :line_items do |t|
      t.references :purchase_order, null: false, foreign_key: true
      t.string :sku, null: false
      t.string :brand
      t.string :title
      t.string :skuvault_product_id
      t.string :received_quantity
      t.string :received_date
      t.string :retail_cost
      t.text :public_notes
      t.text :private_notes
      t.integer :quantity, null: false
      t.float :cost
      t.timestamps null: false
    end

    add_index :line_items, :sku
  end
end
