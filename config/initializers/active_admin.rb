# frozen_string_literal: true

ActiveAdmin.setup do |config|
  config.site_title = "DSS Vendor Portal"
  config.authentication_method = :authenticate_admin_user!
  config.current_user_method = :current_admin_user
  config.logout_link_path = :destroy_admin_user_session_path
  config.root_to = "dealers#index"
  config.comments = true
  config.batch_actions = true
end
