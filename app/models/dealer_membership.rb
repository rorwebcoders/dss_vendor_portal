class DealerMembership < ApplicationRecord
  belongs_to :dealer
  belongs_to :user

  validates :user_id, uniqueness: { scope: :dealer_id }

end
