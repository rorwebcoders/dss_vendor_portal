# frozen_string_literal: true

ActiveAdmin.register LineItem do
  permit_params :purchase_order_id, :sku, :brand, :title, :quantity, :cost

  includes purchase_order: :dealer

  index do
    selectable_column
    id_column
    column :purchase_order
    column("Dealer") { |line_item| line_item.purchase_order.dealer.name }
    column :sku
    column :brand
    column :title
    column :quantity
    column :cost
    actions
  end

  filter :purchase_order
  filter :sku
  filter :brand
  filter :title

  form do |f|
    f.inputs do
      f.input :purchase_order, collection: PurchaseOrder.includes(:dealer).order(:po_number).map { |po| ["#{po.po_number} - #{po.dealer.name}", po.id] }
      f.input :sku
      f.input :brand
      f.input :title
      f.input :quantity
      f.input :cost
    end
    f.actions
  end
end
