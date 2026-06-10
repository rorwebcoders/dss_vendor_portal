# frozen_string_literal: true

ActiveAdmin.register Dealer do
  permit_params :dealer_name, :abbreviation, :api_name, :api_location_code, :email, :enabled, :dealer_address1, :dealer_city, :dealer_state, :dealer_zip, :dealer_country, :sm_dealer_id, user_ids: []

  actions :index, :show

  index do
    selectable_column
    id_column
    column :dealer_name
    column :abbreviation
    column :sm_dealer_id
    column :dealer_address1
    column :enabled
    column("Users") { |dealer| dealer.users.order(:email).pluck(:email).join(", ") }
    actions
  end

  filter :dealer_name
  filter :abbreviation
  filter :sm_dealer_id
  filter :dealer_address1
  filter :enabled
  filter :users

  show do
    attributes_table do
      row :id
      row :dealer_name
      row :abbreviation
      row :dealer_address1
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
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs "Dealer Details" do
      f.input :dealer_name
      f.input :abbreviation
      f.input :dealer_address1
      f.input :sm_dealer_id
      f.input :enabled
    end

    f.inputs "User Access" do
      f.input :users, as: :check_boxes, collection: User.order(:email), hint: "Uncheck a user to immediately remove access to this dealer's purchase orders."
    end

    f.actions
  end
end
