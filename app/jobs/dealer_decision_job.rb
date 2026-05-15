class DealerDecisionJob < ApplicationJob
  queue_as :default

  def perform(po_id, dealer_id, action)
    po = PurchaseOrder.find(po_id)

    # return if po.dealer_response.in?(%w[accepted label_created shipped non_dropshipping])

    case action
    when "accept"
      handle_accept(po, dealer_id)
    when "reject"
      handle_reject(po, dealer_id)
    end
  end

private
  def handle_accept(po, dealer_id)
    # SkuMonsterClient.reserve_inventory!(
    #   dealer_id: dealer_id,
    #   purchase_order: po
    # )

    # @purchase_order.accept_by_dealer!

    po.update!(dealer_response: "accepted", dealer_id: dealer_id)

    LabelGenerationJob.perform_later(po.id)
  end

  def handle_reject(po, dealer_id)
    SkuMonsterClient.block_dealer_inventory!(
      request_body: po.notified_sm_request
    )

    po.update!(
      dealer_id: nil,
      dealer_response: :nil
    )
  end
end