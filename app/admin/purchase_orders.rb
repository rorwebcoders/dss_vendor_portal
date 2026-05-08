# frozen_string_literal: true

ActiveAdmin.register PurchaseOrder do
  permit_params :dealer_id, :po_id, :po_number, :po_type, :dealer_response,
                line_items_attributes: %i[id sku brand title quantity cost _destroy]

  includes :dealer

  scope :all, default: true
  scope("Assigned") { |purchase_orders| purchase_orders.where.not(dealer_id: nil) }
  scope("Unassigned") { |purchase_orders| purchase_orders.where(dealer_id: nil) }

  index do
    selectable_column
    id_column
    column :po_number
    column :po_id
    column :po_type
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
  filter :dealer_response, as: :select, collection: PurchaseOrder::DEALER_RESPONSES
  filter :dealer
  filter :created_at

  show do
    attributes_table do
      row :id
      row("Dealer") { |purchase_order| purchase_order.dealer&.name || status_tag("Unassigned") }
      row :po_id
      row :po_number
      row :po_type
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
      f.input :po_number
      f.input :po_type
      f.input :dealer_response,
              as: :select,
              collection: PurchaseOrder::DEALER_RESPONSES.map { |response| [response.titleize, response] },
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
