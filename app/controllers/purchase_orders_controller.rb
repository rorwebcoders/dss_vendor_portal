class PurchaseOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_accessible_purchase_order, only: :show

  PER_PAGE = 10

  def index
    purchase_orders = current_user.accessible_purchase_orders.includes(:dealer).order(created_at: :desc)
    @total_purchase_orders = purchase_orders.count
    @total_pages = (@total_purchase_orders / PER_PAGE.to_f).ceil
    @current_page = [[params[:page].to_i, 1].max, [@total_pages, 1].max].min
    @purchase_orders = purchase_orders.offset((@current_page - 1) * PER_PAGE).limit(PER_PAGE)
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
