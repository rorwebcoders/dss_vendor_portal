class Dealer < ApplicationRecord
  has_many :dealer_memberships, dependent: :destroy
  has_many :users, through: :dealer_memberships
  has_many :purchase_orders, dependent: :restrict_with_error

  validates :name, presence: true
  validates :abbreviation, presence: true
  validates :enabled, inclusion: { in: [true, false] }

  scope :enabled, -> { where(enabled: true) }

  def display_name
    name
  end

  def to_s
    display_name
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[abbreviation api_location_code api_name created_at email enabled id name updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[dealer_memberships purchase_orders users]
  end
end
