module AdminUsers
  class SessionsController < ActiveAdmin::Devise::SessionsController
    after_action :clear_stale_authentication_alert, only: :create

    private

    def clear_stale_authentication_alert
      return unless admin_user_signed_in?

      flash.delete(:alert) if flash[:alert] == I18n.t("devise.failure.unauthenticated")
    end
  end
end
