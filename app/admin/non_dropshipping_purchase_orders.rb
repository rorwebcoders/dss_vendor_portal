ActiveAdmin.register PurchaseOrder, as: "NonDropshippingPurchaseOrders" do
  menu parent: "Purchase  Orders", label: "Non-Dropshipping Purchase Orders"
  includes :dealer

  actions :index, :show

  controller do
    def scoped_collection
      super.where(status: :non_dropshipping)
    end
  end

  index do
    selectable_column
    id_column
    column("Status") do |purchase_order|
      status_tag(purchase_order.status.titleize)
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
      row :status 
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
      table_for resource.line_items.order(:id) do
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
      f.input :skuvault_id
      f.input :skuvault_marketplace_id
      f.input :skuvault_channel_id
      f.input :shipping_firstname
      f.input :shipping_lastname
      f.input :shipping_company
      f.input :shipping_phone
      f.input :shipping_email
      f.input :po_number
      f.input :tracking_number
      f.input :shipstation_label_url
      f.input :weight
      f.input :units
      f.input :length
      f.input :width
      f.input :height
      f.input :dealer_response,
              as: :select,
              collection: PurchaseOrder.dealer_responses.keys.map { |k| [k.titleize, k] },
              include_blank: "Empty"
    end
    f.inputs "Line Items" do
      f.has_many :line_items, allow_destroy: true, new_record: "Add Line Item" do |line_item|
        line_item.input :sku
        line_item.input :quantity
        line_item.input :cost
      end
    end
    f.actions
  end
end