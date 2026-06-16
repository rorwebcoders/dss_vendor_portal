class Dealer < ApplicationRecord
  has_many :dealer_memberships, dependent: :destroy
  has_many :users, through: :dealer_memberships
  has_many :purchase_orders, dependent: :restrict_with_error

  has_many :dealer_service_codes, dependent: :destroy
  has_many :service_codes, through: :dealer_service_codes
  has_many :carriers, through: :service_codes
  accepts_nested_attributes_for :dealer_service_codes, allow_destroy: true

  validates :dealer_name, presence: true
  validates :abbreviation, presence: true
  validates :enabled, inclusion: { in: [true, false] }

  scope :enabled, -> { where(enabled: true) }

  def display_name
    dealer_name
  end

  def to_s
    display_name
  end
end
