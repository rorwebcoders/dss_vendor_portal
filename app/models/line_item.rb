class LineItem < ApplicationRecord
  belongs_to :purchase_order

  validates :purchase_order, presence: true
  validates :sku, presence: true
  validates :quantity, presence: true

end
