# frozen_string_literal: true

ActiveAdmin.register Dealer do
  permit_params :name, :abbreviation, :api_name, :api_location_code, :email, :enabled, :dealer_address1, :dealer_city, :dealer_state, :dealer_zip, :dealer_country, :sm_dealer_id, user_ids: []

  index do
    selectable_column
    id_column
    column :name
    column :abbreviation
    column :api_name
    column :api_location_code
    column :email
    column :enabled
    column("Users") { |dealer| dealer.users.order(:email).pluck(:email).join(", ") }
    actions
  end

  filter :name
  filter :abbreviation
  filter :api_name
  filter :api_location_code
  filter :enabled
  filter :users

  show do
    attributes_table do
      row :id
      row :name
      row :abbreviation
      row :api_name
      row :api_location_code
      row :email
      row :dealer_address1
      row :dealer_city
      row :dealer_state
      row :dealer_zip
      row :dealer_country
      row :sm_dealer_id
      row :enabled
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
        column :po_id
        column :po_type
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs "Dealer Details" do
      f.input :name
      f.input :abbreviation
      f.input :api_name
      f.input :api_location_code
      f.input :email
      f.input :dealer_address1
      f.input :dealer_city
      f.input :dealer_state
      f.input :dealer_zip
      f.input :dealer_country, as: :string
      f.input :sm_dealer_id
      f.input :enabled
    end

    f.inputs "User Access" do
      f.input :users, as: :check_boxes, collection: User.order(:email), hint: "Uncheck a user to immediately remove access to this dealer's purchase orders."
    end

    f.actions
  end
end
