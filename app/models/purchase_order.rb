class PurchaseOrder < ApplicationRecord
  belongs_to :dealer, optional: true

  has_many :line_items, dependent: :destroy
  accepts_nested_attributes_for :line_items, allow_destroy: true

  before_validation :sync_dealer_response_with_assignment
  after_update :run_dealer_response_callback, if: :saved_change_to_dealer_response?

  enum :status, { pending: 0, processing: 1, error: 2, completed: 3, non_dropshipping: 4, dropshipping: 5, label_created: 6 }, suffix: true
  enum :dealer_response, { pending: 0, accepted: 1 }, suffix: true

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

  def accept_by_dealer!
    update!(dealer_response: :accepted)
  end

  def reject_by_dealer!(current_user_id)
    DealerLog.create(purchase_order_id: self.id, dealer_id: current_user_id, rejected_at: Time.now, status: :rejected)
    update!(dealer_response: nil, dealer: nil, po_number: nil, status: :pending)
  end

private
  def sync_dealer_response_with_assignment
    self.dealer_response = nil if dealer_id.blank?
    self.dealer_response = "pending" if dealer_id.present? && dealer_response.blank?
  end

  def run_dealer_response_callback
    puts "Hi this is accepted" if accepted_by_dealer?
  end
end
