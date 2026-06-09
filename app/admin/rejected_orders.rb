ActiveAdmin.register RejectedOrder do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :purchase_order_id, :dealer_id, :po_number, :rejected_at, :status, :purchase_order_data, :line_items_data, :user_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:purchase_order_id, :dealer_id, :po_number, :rejected_at, :status, :purchase_order_data, :line_items_data, :user_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  index do
    selectable_column
    id_column
    column :po_number
    column("Dealer") do |rejected_order|
      link_to(rejected_order&.dealer&.dealer_name, admin_dealer_path(rejected_order&.dealer))
    end
    column("PurchaseOrder") do |rejected_order|
      purchase_order = PurchaseOrder.find(rejected_order&.purchase_order_id)
      link_to(purchase_order&.id, admin_purchase_order_path(purchase_order))
    end
    column :rejected_at
    column :status
    column("User") do |rejected_order|
      user = User.find_by(id: rejected_order&.user_id)
      path = admin_user_path(user) rescue ''
      link_to(user&.email, path)
    end
    actions
  end
end
