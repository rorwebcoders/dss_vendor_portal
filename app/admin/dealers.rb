# frozen_string_literal: true

ActiveAdmin.register Dealer do
  permit_params :dealer_name, :abbreviation, :enabled, :sm_dealer_id, user_ids: [], service_code_ids: []
  actions :index, :show, :edit

  index do
    selectable_column
    id_column
    column :dealer_name
    column :abbreviation
    column :sm_dealer_id
    column :dealership_name
    column :shipstation_service_codes
    column :shipstation_warehouse_id
    column :enabled
    column("Users") { |dealer| dealer.users.order(:email).pluck(:email).join(", ") }
    actions
  end

  filter :dealer_name
  filter :abbreviation
  filter :sm_dealer_id
  filter :shipstation_warehouse_id
  filter :enabled
  filter :users

  show do
    attributes_table do
      row :id
      row :dealer_name
      row :abbreviation
      row :sm_dealer_id
      row :enabled
      row :address_line1
      row :address_line2
      row :address_line3
      row :city_locality
      row :state_province
      row :postal_code
      row :country_code
      row :dealership_name
      row :phone
      row :shipstation_service_codes
      row :shipstation_warehouse_id
      row :shipstation_request
      row :shipstation_response
      row :created_at
      row :updated_at
    end

    panel "Assigned Users" do
      table_for dealer.users.order(:email) do
        column :email
        column :created_at
      end
    end

    panel "Purchase Orders" do
      table_for dealer.purchase_orders.order(created_at: :desc) do
        column :po_number do |purchase_order|
          link_to purchase_order.po_number, admin_purchase_order_path(purchase_order)
        end
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs "Dealer Details" do
      f.input :dealer_name, input_html: { disabled: true, readonly: true }
      f.input :abbreviation, input_html: { disabled: true, readonly: true }
      f.input :sm_dealer_id, input_html: { disabled: true, readonly: true }
      f.input :enabled
      f.input :service_codes,
        as: :searchable_select,
        multiple: true,
        collection: ServiceCode.includes(:carrier)
        .order('carriers.shipstation_friendly_name, service_codes.shipstation_name')
      end

      # f.inputs "User Access" do
      #   f.input :users, as: :check_boxes, collection: User.order(:email), hint: "Uncheck a user to immediately remove access to this dealer's purchase orders."
      # end
    f.actions
  end
end
