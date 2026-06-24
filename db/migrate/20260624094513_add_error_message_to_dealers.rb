class AddErrorMessageToDealers < ActiveRecord::Migration[8.0]
  def change
    add_column :dealers, :error_message, :text
  end
end
