class DealerDecisionJob < ApplicationJob
  queue_as :default

  def perform(po_id, action)
    po = PurchaseOrder.find(po_id)

    case action
    when "reject"
      handle_reject(po)
    end
  end

private
  def handle_reject(po)
    SkuMonsterClient.block_dealer_inventory!(
      request_body: po.notified_sm_request
    )
  end
end