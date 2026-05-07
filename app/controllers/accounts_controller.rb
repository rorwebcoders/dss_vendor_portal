# frozen_string_literal: true

class AccountsController < ApplicationController
  before_action :authenticate_user!

  def edit; end

  def update
    if changing_password?
      update_password
    else
      update_profile
    end
  end

  private

  def changing_password?
    account_params[:current_password].present? || account_params[:password].present? || account_params[:password_confirmation].present?
  end

  def update_profile
    if current_user.update(profile_params)
      redirect_to edit_account_path, notice: "Account details updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_password
    if current_user.update_with_password(password_params)
      bypass_sign_in(current_user)
      redirect_to edit_account_path, notice: "Password updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def account_params
    params.require(:user).permit(:first_name, :last_name, :current_password, :password, :password_confirmation)
  end

  def profile_params
    account_params.slice(:first_name, :last_name)
  end

  def password_params
    account_params.slice(:current_password, :password, :password_confirmation)
  end
end
