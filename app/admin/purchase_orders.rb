# frozen_string_literal: true

ActiveAdmin.register PurchaseOrder do
  permit_params :dealer_id, :po_id, :po_number, :po_type, :dealer_response, :tracking_number, :shipstation_label_url,
                line_items_attributes: %i[id sku brand title quantity cost _destroy]

  includes :dealer

  scope :all, default: true
  scope("Assigned") { |purchase_orders| purchase_orders.where.not(dealer_id: nil) }
  scope("Unassigned") { |purchase_orders| purchase_orders.where(dealer_id: nil) }

  index do
    selectable_column
    id_column
    column("Status") do |purchase_order|
      status_tag(purchase_order.status.titleize)
    end
    column :po_number
    column :po_id
    column :po_type
    column :tracking_number
    column("Response") do |purchase_order|
      if purchase_order.dealer_response.present?
        status_tag(purchase_order.dealer_response.titleize)
      else
        status_tag("Empty")
      end
    end
    column("Dealer") { |purchase_order| purchase_order.dealer&.name || status_tag("Unassigned") }
    column :created_at
    actions
  end

  filter :po_number
  filter :po_id
  filter :po_type
  filter :tracking_number
  filter :dealer_response, as: :select,
       collection: PurchaseOrder.dealer_responses.keys.map { |k| [k.titleize, k] }
  filter :dealer
  filter :created_at

  show do
    attributes_table do
      row :id
      row("Dealer") { |purchase_order| purchase_order.dealer&.name || status_tag("Unassigned") }
      row :po_id
      row :po_number
      row :po_type
      row :tracking_number
      row :shipstation_label_url
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
        column :brand
        column :title
        column :quantity
        column :cost
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs "Purchase Order Details" do
      f.input :dealer, collection: Dealer.order(:name), include_blank: "Unassigned"
      f.input :po_id
      f.input :status
      f.input :po_number
      f.input :po_type
      f.input :tracking_number
      f.input :shipstation_label_url
      f.input :dealer_response,
              as: :select,
              collection: PurchaseOrder.dealer_responses.keys.map { |k| [k.titleize, k] },
              include_blank: "Empty"
    end

    f.inputs "Line Items" do
      f.has_many :line_items, allow_destroy: true, new_record: "Add Line Item" do |line_item|
        line_item.input :sku
        line_item.input :brand
        line_item.input :title
        line_item.input :quantity
        line_item.input :cost
      end
    end

    f.actions
  end
end
