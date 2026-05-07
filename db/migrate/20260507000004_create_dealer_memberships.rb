# frozen_string_literal: true

class CreateDealerMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :dealer_memberships do |t|
      t.references :dealer, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps null: false
    end

    add_index :dealer_memberships, [:dealer_id, :user_id], unique: true
  end
end
