class PurchaseOrder < ApplicationRecord
  belongs_to :dealer
  has_many :line_items, dependent: :destroy

  validates :dealer, presence: true
  validates :po_number, presence: true

  scope :for_dealers, ->(dealer_ids) { where(dealer_id: dealer_ids) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at dealer_id id po_id po_number po_type updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[dealer line_items]
  end
end
