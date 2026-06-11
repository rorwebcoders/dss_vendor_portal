class DealerDecisionJob < ApplicationJob
  queue_as :default

  def perform(po_id, action)
    po = PurchaseOrder.find(po_id)

    # return if po.dealer_response.in?(%w[accepted label_created shipped non_dropshipping])

    case action
    when "accept"
      handle_accept(po)
    when "reject"
      handle_reject(po)
    end
  end

private
  def handle_accept(po)
    LabelGenerationJob.perform_later(po.id)
  end

  def handle_reject(po)
    SkuMonsterClient.block_dealer_inventory!(
      request_body: po.notified_sm_request
    )
  end
end