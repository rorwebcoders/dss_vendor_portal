ActiveAdmin.register Carrier do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :shipstation_carrier_id, :shipstation_carrier_code, :shipstation_friendly_name, :shipstation_account_number, service_codes_attributes: [:id, :is_global, :shipstation_service_code, :shipstation_name, :domestic, :international, :_destroy]
  #
  # or
  #
  # permit_params do
  #   permitted = [:shipstation_carrier_id, :shipstation_carrier_code, :shipstation_friendly_name, :shipstation_account_number, :enabled]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  actions :index, :show, :edit, :update

  index do
    id_column
    column :shipstation_carrier_id
    column :shipstation_carrier_code 
    column :shipstation_friendly_name 
    # column :shipstation_account_number 
    actions
  end

  show do
    attributes_table do
      row :id
      row :shipstation_carrier_id
      row :shipstation_carrier_code 
      row :shipstation_friendly_name 
      # row :shipstation_account_number 
      # row :enabled 
      row :created_at
      row :updated_at
    end

    panel "Service Codes" do
      table_for carrier.service_codes.order(:id) do
        column :shipstation_service_code
        column :shipstation_name
        column :is_global
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs "Carrier Details" do
      f.input :shipstation_carrier_id, input_html: { disabled: true, readonly: true }
      f.input :shipstation_carrier_code, input_html: { disabled: true, readonly: true }
      f.input :shipstation_friendly_name, input_html: { disabled: true, readonly: true }
      # f.input :shipstation_account_number, input_html: { disabled: true, readonly: true }
      # f.input :enabled, input_html: { disabled: true, readonly: true }
    end
    f.inputs "Service Codes" do
      f.has_many :service_codes, allow_destroy: false, new_record: false do |sc|
        sc.input :shipstation_service_code, input_html: { disabled: true, readonly: true }
        sc.input :shipstation_name, input_html: { disabled: true, readonly: true }
        # sc.input :domestic, input_html: { disabled: true, readonly: true }
        # sc.input :international, input_html: { disabled: true, readonly: true }
        sc.input :is_global
      end
    end

    f.actions
  end
end
