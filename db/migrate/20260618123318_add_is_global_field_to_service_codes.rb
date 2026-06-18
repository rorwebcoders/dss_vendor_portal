class AddIsGlobalFieldToServiceCodes < ActiveRecord::Migration[8.0]
  def change
    add_column :service_codes, :is_global, :boolean, default: false, null: false
  end
end
