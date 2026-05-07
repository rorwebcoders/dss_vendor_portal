class LineItem < ApplicationRecord
  belongs_to :purchase_order

  validates :purchase_order, presence: true
  validates :sku, presence: true
  validates :quantity, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[brand cost created_at id purchase_order_id quantity sku title updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[purchase_order]
  end
end
