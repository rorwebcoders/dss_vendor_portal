ActiveAdmin.register_page "ApiToken" do
  menu parent: "Settings", label: "API Tokens"

  FILE_PATH = Rails.root.join("public", "skumonster", "api_tokens.yml")

  content do
    file_data = YAML.load_file(FILE_PATH) rescue {}
    file_data ||= {}

    panel "API Tokens" do
      active_admin_form_for :api_info, url: admin_api_token_update_path, method: :post, as: :api_info do |f|
        f.inputs do
          value = file_data["token"] rescue ''
          f.input :token, input_html: { value: value, readonly: true, style: "width: 500px" }
        end
        f.actions do
          f.action :submit, label: "Generate New Token"
        end
      end
    end
  end
end
