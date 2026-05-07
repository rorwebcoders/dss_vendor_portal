class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_many :dealer_memberships, dependent: :destroy
  has_many :dealers, through: :dealer_memberships

  def display_name
    email
  end

  def to_s
    display_name
  end

  def accessible_purchase_orders
    PurchaseOrder.for_dealers(dealer_ids)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at email id remember_created_at reset_password_sent_at reset_password_token updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[dealer_memberships dealers]
  end
end
