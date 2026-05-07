# frozen_string_literal: true

ActiveAdmin.register PurchaseOrder do
  permit_params :dealer_id, :po_id, :po_number, :po_type,
                line_items_attributes: %i[id sku brand title quantity cost _destroy]

  includes :dealer

  index do
    selectable_column
    id_column
    column :po_number
    column :po_id
    column :po_type
    column :dealer
    column :created_at
    actions
  end

  filter :po_number
  filter :po_id
  filter :po_type
  filter :dealer
  filter :created_at

  show do
    attributes_table do
      row :id
      row :dealer
      row :po_id
      row :po_number
      row :po_type
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
      f.input :dealer, collection: Dealer.order(:name)
      f.input :po_id
      f.input :po_number
      f.input :po_type
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
