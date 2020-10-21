class DeleteController < ApplicationController
  before_action :authenticate_user!, only: %i[show destroy]

  def show; end

  def destroy
    unless current_user.valid_password? params[:current_password]
      @password_error_message = I18n.t("activerecord.errors.models.user.attributes.password.#{params[:current_password].blank? ? 'blank' : 'invalid'}")
      render :show
      return
    end

    current_user.destroy!
    sign_out
    redirect_to account_delete_confirmation_path
  end

  def confirmation; end
end
