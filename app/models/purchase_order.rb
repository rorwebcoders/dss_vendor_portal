class PurchaseOrder < ApplicationRecord
  DEALER_RESPONSES = %w[pending accepted rejected].freeze

  belongs_to :dealer, optional: true
  has_many :line_items, dependent: :destroy

  accepts_nested_attributes_for :line_items, allow_destroy: true

  validates :po_number, presence: true
  validates :dealer_response, inclusion: { in: DEALER_RESPONSES }

  after_update :run_dealer_response_callback, if: :saved_change_to_dealer_response?

  scope :for_dealers, ->(dealer_ids) { where(dealer_id: dealer_ids) }

  def display_name
    po_number
  end

  def to_s
    display_name
  end

  def pending_dealer_response?
    dealer_response == "pending"
  end

  def accepted_by_dealer?
    dealer_response == "accepted"
  end

  def rejected_by_dealer?
    dealer_response == "rejected"
  end

  def accept_by_dealer!
    update!(dealer_response: "accepted")
  end

  def reject_by_dealer!
    update!(dealer_response: "rejected", dealer: nil)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at dealer_id dealer_response id po_id po_number po_type updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[dealer line_items]
  end

  private

  def run_dealer_response_callback
    if accepted_by_dealer?
      puts "Hi this is accepted"
    elsif rejected_by_dealer?
      puts "Hi this is rejected"
    end
  end
end
