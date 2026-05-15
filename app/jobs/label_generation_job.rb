class LabelGenerationJob < ApplicationJob
  queue_as :default

  def perform(po_id)
    po = PurchaseOrder.find(po_id)

    return unless po.dealer_response == "accepted"

    shipment = ShipStationClient.create_label(po)
    
    po.update!(
      tracking_number: shipment[:tracking],
      label_url: shipment[:label_url],
      status: :label_created
    )
  end
end