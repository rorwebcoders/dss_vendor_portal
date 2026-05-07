class PurchaseOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_accessible_purchase_order, only: :show

  def index
    @purchase_orders = current_user.accessible_purchase_orders.includes(:dealer).order(created_at: :desc)
  end

  def show
    @line_items = @purchase_order.line_items.order(:id)
  end

  private

  def set_accessible_purchase_order
    @purchase_order = current_user.accessible_purchase_orders.includes(:dealer, :line_items).find_by(id: params[:id])
    redirect_to purchase_orders_path, alert: "You do not have access to that purchase order." unless @purchase_order
  end
end
