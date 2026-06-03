# frozen_string_literal: true

class CreateLineItems < ActiveRecord::Migration[8.0]
  def change
    create_table :line_items do |t|
      t.string :sku, null: false
      t.string :brand
      t.string :title
      t.string :skuvault_product_id
      t.integer :quantity, null: false
      t.float :cost
      t.references :purchase_order, null: false, foreign_key: true
      t.timestamps null: false
    end
    add_index :line_items, :sku
  end
end
