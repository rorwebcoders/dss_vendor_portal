class Admin::ApiTokenController < ApplicationController
    protect_from_forgery with: :exception

    FILE_PATH = Rails.root.join("public", "skumonster", "api_tokens.yml")

    def update
      data = {}
      data["token"] = SecureRandom.hex(32)

	   FileUtils.mkdir_p(File.dirname(FILE_PATH))
	   File.write(FILE_PATH, data.to_yaml)
       redirect_to admin_apitoken_path, notice: "New API tokens generated successfully"
    end
end


