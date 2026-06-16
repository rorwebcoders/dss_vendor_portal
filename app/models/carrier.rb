class Carrier < ApplicationRecord
  has_many :service_codes, dependent: :destroy
  accepts_nested_attributes_for :service_codes, allow_destroy: true
end
