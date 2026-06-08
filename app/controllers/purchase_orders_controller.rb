class PurchaseOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_accessible_purchase_order, only: %i[show reject]

  PER_PAGE = 10
  SORT_COLUMNS = {
    "po_number" => "purchase_orders.po_number",
    "dealer" => "dealers.dealer_name",
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

    @rejected = params[:rejected].to_s == "true"
    if @rejected
      @rejected_data = RejectedOrder.where(dealer_id: current_user.dealer_ids).includes(:dealer).index_by(&:purchase_order_id).transform_values do |rejected|
        {
          dealer_name: rejected.dealer&.dealer_name,
          status: rejected.status,
          po_number: rejected.po_number
        }
      end
      rejected_purchase_orders = RejectedOrder.where(dealer_id: current_user.dealer_ids)
      rejected_purchase_order_ids = rejected_purchase_orders.pluck(:purchase_order_id)
      base_purchase_orders = PurchaseOrder.where(id: rejected_purchase_order_ids)
      @purchase_order_summary_cards = purchase_order_summary_cards(base_purchase_orders)
     
      filtered_purchase_orders = if @query.present?
        filtered_rejected_purchase_orders = search_purchase_orders(rejected_purchase_orders)
        PurchaseOrder.where(id: filtered_rejected_purchase_orders.pluck(:purchase_order_id))
      else
        base_purchase_orders
      end
      purchase_orders = filtered_purchase_orders.includes(:dealer)
    else
      base_purchase_orders = current_user.accessible_purchase_orders.left_joins(:dealer)
      @purchase_order_summary_cards = purchase_order_summary_cards(base_purchase_orders)
      filtered_purchase_orders = @query.present? ? search_purchase_orders(base_purchase_orders) : base_purchase_orders
      purchase_orders = filtered_purchase_orders.includes(:dealer)
      purchase_orders = purchase_orders.where(dealer_response: @status_filter) unless @status_filter == "all"
      purchase_orders = purchase_orders.order(
        Arel.sql("#{SORT_COLUMNS.fetch(@sort_column)} #{@sort_direction.upcase}"),
        id: :desc
      )
    end

    @total_purchase_orders = purchase_orders.count
    @total_pages = (@total_purchase_orders / PER_PAGE.to_f).ceil
    @current_page = [[params[:page].to_i, 1].max, [@total_pages, 1].max].min
    # @purchase_orders = purchase_orders.offset((@current_page - 1) * PER_PAGE).limit(PER_PAGE)

    @page = params[:page].to_i
    @page = 1 if @page < 1
    @purchase_orders = purchase_orders.order(created_at: :desc).offset((@page - 1) * PER_PAGE).limit(PER_PAGE)

    @has_more = purchase_orders.count > @page * PER_PAGE
  end

  def show
    @rejected = params[:rejected].to_s == "true"
    if @rejected
      @rejected_order = RejectedOrder.where(dealer_id: current_user.dealer_ids).find_by(purchase_order_id: @purchase_order.id)
    end

    line_items = @purchase_order.line_items.order(:id)
    @total_line_items = line_items.count
    
    @page = params[:page].to_i
    @page = 1 if @page < 1
    @line_items = line_items.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)

    @has_more = line_items.count > @page * PER_PAGE
  end

  def update
    purchase_order = PurchaseOrder.find(params[:id])
    purchase_order.accept_by_dealer!

    if purchase_order.update(shipping_params)
      DealerDecisionJob.perform_later(purchase_order.id, current_user.id, "accept")

      redirect_to purchase_order_path(purchase_order), notice: "Purchase order accepted. Label generation has been queued."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # def accept
  #   @purchase_order.accept_by_dealer!
    
  #   redirect_to purchase_order_path(@purchase_order), notice: "Purchase order accepted. Please provide shipping dimensions."
  # end

  def reject
    @purchase_order.reject_by_dealer!(current_user.id)

    DealerDecisionJob.perform_later(@purchase_order.id, current_user.id, "reject")

    redirect_to purchase_orders_path, notice: "Purchase order rejected, unassigned, and cleared for reassignment."
  end

private
  def shipping_params 
    params.require(:purchase_order).permit(:weight, :units, :length, :width, :height)
  end

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
        value: RejectedOrder.where(dealer_id: current_user.dealer_ids, status: :rejected).count,
        detail: "Rejected in last 30 days",
        modifier: "rejected"
      }
    ]
  end

  def search_purchase_orders(purchase_orders)
    term = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
    if @rejected
      purchase_orders.where(
        <<~SQL.squish,
          rejected_orders.po_number LIKE :term
        SQL
        term: term
      )
    else
      purchase_orders.where(
        <<~SQL.squish,
          purchase_orders.po_number LIKE :term OR
          purchase_orders.dealer_response LIKE :term OR
          dealers.dealer_name LIKE :term
        SQL
        term: term
      )
    end
  end

  def set_accessible_purchase_order
    unless params[:rejected].to_s == "true" 
      @purchase_order = current_user.accessible_purchase_orders.includes(:dealer, :line_items).find_by(id: params[:id])
      redirect_to purchase_orders_path, alert: "You do not have access to that purchase order." unless @purchase_order
    else
      @purchase_order = PurchaseOrder.includes(:line_items).find_by(id: params[:id])
    end
  end
end
