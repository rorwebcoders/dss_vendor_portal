class PurchaseOrder < ApplicationRecord
  DEALER_RESPONSES = %w[pending accepted].freeze

  belongs_to :dealer, optional: true
  has_many :line_items, dependent: :destroy

  accepts_nested_attributes_for :line_items, allow_destroy: true

  validates :po_number, presence: true
  validates :dealer_response, inclusion: { in: DEALER_RESPONSES }, allow_nil: true

  before_validation :sync_dealer_response_with_assignment
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

  def accept_by_dealer!
    update!(dealer_response: "accepted")
  end

  def reject_by_dealer!
    update!(dealer_response: nil, dealer: nil)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at dealer_id dealer_response id po_id po_number po_type updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[dealer line_items]
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
