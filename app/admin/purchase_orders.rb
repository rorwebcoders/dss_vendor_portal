# frozen_string_literal: true

ActiveAdmin.register PurchaseOrder do
  menu parent: "Purchase  Orders", label: "Dropship Orders"
  permit_params :dealer_id, :po_number, :skuvault_status, :shipping_name, :shipping_address1, :shipping_city, :shipping_state,
  :shipping_zip, :shipping_country, :skuvault_id, :skuvault_marketplace_id, :skuvault_channel_id, :shipping_firstname,
  :shipping_lastname, :shipping_company, :shipping_phone, :shipping_email, :tracking_number, :shipstation_label_url,
  :weight, :units, :length, :width, :height, :notified_sm_request, :status, :dealer_response, 
  line_items_attributes: %i[id sku brand title quantity cost _destroy]

  controller do
    def scoped_collection
      super.where.not(status: PurchaseOrder.statuses[:non_dropshipping])
    end
  end

  includes :dealer

  scope :all, default: true
  scope("Assigned") { |purchase_orders| purchase_orders.where.not(dealer_id: nil) }
  scope("Unassigned") { |purchase_orders| purchase_orders.where(dealer_id: nil) }

  index do
    selectable_column
    id_column
    column("Status") do |purchase_order|
      status_tag(
        purchase_order.status.titleize,
        class: "status-#{purchase_order.status}"
      )
    end
    column :shipping_firstname
    column :po_number
    column :tracking_number
    column("Response") do |purchase_order|
      if purchase_order.dealer_response.present?
        status_tag(purchase_order.dealer_response.titleize)
      else
        status_tag("Empty")
      end
    end
    column("Dealer") { |purchase_order| purchase_order.dealer&.dealer_name || status_tag("Unassigned") }
    column :created_at
    actions
  end

  filter :po_number
  filter :po_id
  filter :tracking_number
  filter :dealer_response, as: :select,
       collection: PurchaseOrder.dealer_responses.keys.map { |k| [k.titleize, k] }
  filter :dealer
  filter :created_at

  show do
    attributes_table do
      row :id
      row("Dealer") { |purchase_order| purchase_order.dealer&.dealer_name || status_tag("Unassigned") }
      row :po_number 
      row :skuvault_status 
      row :shipping_name 
      row :shipping_address1 
      row :shipping_city 
      row :shipping_state 
      row :shipping_zip 
      row :shipping_country 
      row :skuvault_id 
      row :skuvault_marketplace_id 
      row :skuvault_channel_id 
      row :shipping_firstname 
      row :shipping_lastname 
      row :shipping_company 
      row :shipping_phone 
      row :shipping_email 
      row :tracking_number 
      row :shipstation_label_url 
      row :weight 
      row :units 
      row :length 
      row :width 
      row :height 
      row :notified_sm_request
      row("Status") do |purchase_order|
      status_tag(
        purchase_order.status.titleize,
        class: "status-#{purchase_order.status}"
      )
    end
      row("Response") do |purchase_order|
        if purchase_order.dealer_response.present?
          status_tag(purchase_order.dealer_response.titleize)
        else
          status_tag("Empty")
        end
      end
      row :created_at
      row :updated_at
    end

    panel "Line Items" do
      table_for purchase_order.line_items.order(:id) do
        column :sku
        column :quantity
        column :cost
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs "Purchase Order Details" do
      f.input :dealer, collection: Dealer.order(:dealer_name), include_blank: "Unassigned"
      f.input :status
      f.input :skuvault_id, input_html: { disabled: true, readonly: true }
      f.input :skuvault_marketplace_id, input_html: { disabled: true, readonly: true }
      f.input :skuvault_channel_id, input_html: { disabled: true, readonly: true }
      f.input :shipping_firstname, input_html: { disabled: true, readonly: true }
      f.input :shipping_lastname, input_html: { disabled: true, readonly: true }
      f.input :shipping_company, input_html: { disabled: true, readonly: true }
      f.input :shipping_phone, input_html: { disabled: true, readonly: true }
      f.input :shipping_email, input_html: { disabled: true, readonly: true }
      f.input :po_number, input_html: { disabled: true, readonly: true }
      f.input :tracking_number, input_html: { disabled: true, readonly: true }
      f.input :shipstation_label_url, input_html: { disabled: true, readonly: true }
      f.input :weight, input_html: { disabled: true, readonly: true }
      f.input :units, input_html: { disabled: true, readonly: true }
      f.input :length, input_html: { disabled: true, readonly: true }
      f.input :width, input_html: { disabled: true, readonly: true }
      f.input :height, input_html: { disabled: true, readonly: true }
      f.input :dealer_response,
              as: :select,
              collection: PurchaseOrder.dealer_responses.keys.map { |k| [k.titleize, k] },
              include_blank: "Empty", input_html: { disabled: true, readonly: true }
    end
    f.inputs "Line Items" do
      f.has_many :line_items, allow_destroy: false, new_record: false do |line_item|
        line_item.input :sku, input_html: { disabled: true, readonly: true }
        line_item.input :quantity, input_html: { disabled: true, readonly: true }
        line_item.input :cost, input_html: { disabled: true, readonly: true }
      end
    end
    f.actions
  end
end
