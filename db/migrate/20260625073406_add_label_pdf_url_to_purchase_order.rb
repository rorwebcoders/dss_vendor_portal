class AddLabelPdfUrlToPurchaseOrder < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_orders, :shipstation_label_pdf_url, :string
  end
end
