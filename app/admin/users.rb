# frozen_string_literal: true

ActiveAdmin.register User do
  permit_params :email, :password, :password_confirmation, dealer_ids: []

  index do
    selectable_column
    id_column
    column :email
    column("Dealers") { |user| user.dealers.order(:name).pluck(:name).join(", ") }
    column :created_at
    actions
  end

  filter :email
  filter :dealers
  filter :created_at

  show do
    attributes_table do
      row :id
      row :email
      row("Dealers") { |user| user.dealers.order(:name).pluck(:name).join(", ") }
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :dealers, as: :check_boxes, collection: Dealer.order(:name)
    end
    f.actions
  end
end
