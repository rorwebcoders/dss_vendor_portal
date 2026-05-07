class DealerMembership < ApplicationRecord
  belongs_to :dealer
  belongs_to :user

  validates :user_id, uniqueness: { scope: :dealer_id }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at dealer_id id updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[dealer user]
  end
end
