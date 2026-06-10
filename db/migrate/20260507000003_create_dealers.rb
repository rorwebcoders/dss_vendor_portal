# frozen_string_literal: true

class CreateDealers < ActiveRecord::Migration[8.0]
  def change
    create_table :dealers do |t|
      t.integer :sm_dealer_id
      t.string :abbreviation, null: false
      t.string :dealer_name, null: false
      t.string :dealer_address
      t.boolean :enabled, null: false, default: true
      t.timestamps null: false
    end
    add_index :dealers, :sm_dealer_id
    add_index :dealers, :abbreviation
    add_index :dealers, :enabled
  end
end
