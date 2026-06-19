class Dealer < ApplicationRecord
  has_many :dealer_memberships, dependent: :destroy
  has_many :users, through: :dealer_memberships
  has_many :purchase_orders, dependent: :restrict_with_error

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
