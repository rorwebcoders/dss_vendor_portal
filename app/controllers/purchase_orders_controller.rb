class PurchaseOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_accessible_purchase_order, only: %i[show accept reject]

  PER_PAGE = 10
  SORT_COLUMNS = {
    "po_number" => "purchase_orders.po_number",
    "po_id" => "purchase_orders.po_id",
    "po_type" => "purchase_orders.po_type",
    "dealer" => "dealers.name",
    "status" => "purchase_orders.dealer_response",
    "created" => "purchase_orders.created_at"
  }.freeze
  SORT_DIRECTIONS = %w[asc desc].freeze
  DEFAULT_SORT = "created"
  DEFAULT_DIRECTION = "desc"
  STATUS_FILTERS = {
    "all" => "All order",
    "pending" => "Pending Orders",
    "accepted" => "Accepted Orders"
  }.freeze
  def index
    @query = params[:q].to_s.strip
    @sort_column = SORT_COLUMNS.key?(params[:sort]) ? params[:sort] : DEFAULT_SORT
    @sort_direction = SORT_DIRECTIONS.include?(params[:direction]) ? params[:direction] : DEFAULT_DIRECTION
    @status_filter = STATUS_FILTERS.key?(params[:status]) ? params[:status] : STATUS_FILTERS.keys.first
    @status_filters = STATUS_FILTERS

    base_purchase_orders = current_user.accessible_purchase_orders.left_joins(:dealer)
    @purchase_order_summary_cards = purchase_order_summary_cards(base_purchase_orders)
    filtered_purchase_orders = @query.present? ? search_purchase_orders(base_purchase_orders) : base_purchase_orders
    purchase_orders = filtered_purchase_orders.includes(:dealer)
    purchase_orders = purchase_orders.where(dealer_response: @status_filter) unless @status_filter == "all"
    purchase_orders = purchase_orders.order(
      Arel.sql("#{SORT_COLUMNS.fetch(@sort_column)} #{@sort_direction.upcase}"),
      id: :desc
    )

    @total_purchase_orders = purchase_orders.count
    @total_pages = (@total_purchase_orders / PER_PAGE.to_f).ceil
    @current_page = [[params[:page].to_i, 1].max, [@total_pages, 1].max].min
    @purchase_orders = purchase_orders.offset((@current_page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  def show
    @line_items = @purchase_order.line_items.order(:id)
  end

  def accept
    @purchase_order.accept_by_dealer!
    
    DealerDecisionJob.perform_later(@purchase_order.id, current_user.id, "accept")

    redirect_to purchase_order_path(@purchase_order), notice: "Purchase order accepted."
  end

  def reject
    @purchase_order.reject_by_dealer!(current_user.id)

    DealerDecisionJob.perform_later(@purchase_order.id, current_user.id, "reject")

    redirect_to purchase_orders_path, notice: "Purchase order rejected, unassigned, and cleared for reassignment."
  end

  private

  def purchase_order_summary_cards(purchase_orders)
    recent_orders = purchase_orders.where(updated_at: 30.days.ago..)
    open_orders_count = purchase_orders.where(dealer_response: :pending).count

    [
      {
        label: "All Open Orders",
        value: open_orders_count,
        detail: "#{open_orders_count} need acknowledgement",
        modifier: "open"
      },
      {
        label: "Accepted Orders (30d)",
        value: recent_orders.where(dealer_response: :accepted).count,
        detail: "Accepted in last 30 days",
        modifier: "accepted"
      },
      {
        label: "Rejected Orders (30d)",
        value: DealerLog.where(dealer_id: current_user.id, status: :rejected).count,
        detail: "Rejected in last 30 days",
        modifier: "rejected"
      }
    ]
  end

  def search_purchase_orders(purchase_orders)
    term = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"

    purchase_orders.where(
      <<~SQL.squish,
        purchase_orders.po_number LIKE :term OR
        CAST(purchase_orders.po_id AS CHAR) LIKE :term OR
        purchase_orders.po_type LIKE :term OR
        purchase_orders.dealer_response LIKE :term OR
        dealers.name LIKE :term
      SQL
      term: term
    )
  end

  def set_accessible_purchase_order
    @purchase_order = current_user.accessible_purchase_orders.includes(:dealer, :line_items).find_by(id: params[:id])
    redirect_to purchase_orders_path, alert: "You do not have access to that purchase order." unless @purchase_order
  end
end
