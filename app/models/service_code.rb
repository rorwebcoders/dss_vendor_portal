class ServiceCode < ApplicationRecord
  belongs_to :carrier

  def display_name
    "#{carrier.shipstation_friendly_name} - #{shipstation_name}"
  end
end
