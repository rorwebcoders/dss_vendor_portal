# frozen_string_literal: true

class CreateLineItems < ActiveRecord::Migration[8.0]
  def change
    create_table :line_items do |t|
      t.references :purchase_order, null: false, foreign_key: true
      t.string :sku, null: false
      t.string :brand
      t.string :title
      t.integer :quantity, null: false
      t.float :cost
      t.timestamps null: false
    end

    add_index :line_items, :sku
  end
end
