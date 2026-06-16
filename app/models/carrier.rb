class Carrier < ApplicationRecord
  has_many :service_codes, dependent: :destroy
end
