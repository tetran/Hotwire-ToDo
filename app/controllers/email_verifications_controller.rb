class EmailVerificationsController < ApplicationController
  include VerifyEmail

  skip_before_action :require_login, only: [:show]
  before_action :set_user, only: [:show]

  def show
    logger.debug { "Email verification token: #{params[:id]}, User: #{@user.id}" }
    @user.update! verified: true
    redirect_to root_path, success: t("controllers.email_verifications.show.success")
  end

  def create
    send_email_verification
    respond_to do |format|
      @message = t("controllers.email_verifications.create.success")
      format.turbo_stream
    end
  end

  private

    def set_user
      @user = User.find_by_token_for!(:email_verification, params[:id])
    rescue StandardError
      redirect_to root_path, error: t("controllers.email_verifications.invalid_token")
    end
end
