class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_many :dealer_memberships, dependent: :destroy
  has_many :dealers, through: :dealer_memberships

  def full_name
    [first_name, last_name].compact_blank.join(" ")
  end

  def display_name
    full_name.presence || email
  end

  def to_s
    display_name
  end

  def accessible_purchase_orders
    PurchaseOrder.for_dealers(dealer_ids)
  end

end
