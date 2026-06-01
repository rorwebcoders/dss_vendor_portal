class LabelGenerationJob < ApplicationJob
  queue_as :default

  def perform(po_id)
    po = PurchaseOrder.find(po_id)

    return unless po.dealer_response.to_s == "accepted"

    shipment = if Rails.env.development?
      {
        tracking: "TEST-#{SecureRandom.hex(6).upcase}",
        label_url: "https://shpstation.com/test-label.pdf"
      }
    else
      ShipStationClient.create_label(po)
    end
    
    po.update!(
      tracking_number: shipment[:tracking],
      shipstation_label_url: shipment[:label_url],
      status: :label_created
    )
  end
end