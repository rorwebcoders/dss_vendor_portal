class AddAddressFieldsToDealers < ActiveRecord::Migration[8.0]
  def change
    add_column :dealers, :address_line1, :string
    add_column :dealers, :address_line2, :string
    add_column :dealers, :address_line3, :string
    add_column :dealers, :city_locality, :string
    add_column :dealers, :state_province, :string
    add_column :dealers, :postal_code, :string
    add_column :dealers, :country_code, :string
    add_column :dealers, :dealership_name, :string
    add_column :dealers, :phone, :string
    add_column :dealers, :shipstation_service_codes, :json
    add_column :dealers, :shipstation_warehouse_id, :string
    add_column :dealers, :shipstation_request, :text
    add_column :dealers, :shipstation_response, :text
  end
end
