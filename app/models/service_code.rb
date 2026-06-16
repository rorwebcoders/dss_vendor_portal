class ServiceCode < ApplicationRecord
  belongs_to :carrier

  has_many :dealer_service_codes, dependent: :destroy
  has_many :dealers, through: :dealer_service_codes

  def display_name
    "#{carrier.shipstation_friendly_name} - #{shipstation_name}"
  end
end
