# frozen_string_literal: true

ActiveAdmin.register User do
  permit_params :email, :first_name, :last_name, :password, :password_confirmation, dealer_ids: []

  index do
    selectable_column
    id_column
    column :email
    column :first_name
    column :last_name
    column("Dealers") { |user| user.dealers.order(:dealer_name).pluck(:dealer_name).join(", ") }
    column :created_at
    actions
  end

  filter :email
  filter :dealers,
    as: :searchable_select,
    url: proc { searchable_select_options_admin_dealers_path },
    fields: [:dealer_name],
    text_attribute: :dealer_name,
    minimum_input_length: 2,
    order_by: 'dealer_name_asc'
  # filter :dealers
  filter :created_at

  show do
    attributes_table do
      row :id
      row :email
      row :first_name
      row :last_name
      row("Dealers") { |user| user.dealers.order(:dealer_name).pluck(:dealer_name).join(", ") }
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :email
      f.input :first_name
      f.input :last_name
      # f.input :password
      # f.input :password_confirmation
      f.input :dealers,
        as: :searchable_select,
        multiple: true,
        collection: Dealer.order(dealer_name: :asc)
    end
    f.actions
  end
end
