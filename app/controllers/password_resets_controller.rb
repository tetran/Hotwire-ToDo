class PasswordResetsController < ApplicationController
  skip_before_action :require_login
  before_action :set_user_from_token, only: [:edit, :update]

  def new
    @password_reset = PasswordReset.new
  end

  def create
    @password_reset = PasswordReset.new(params[:password_reset].permit(:email))
    if @password_reset.valid?
      send_password_reset
      redirect_to login_path, success: "Check your email for reset instructions"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @user.assign_attributes(update_params)
    if @user.save(context: :update_password)
      redirect_to login_path, success: "Password updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def send_password_reset
      user = User.find_by(email: @password_reset.email, verified: true)
      UserMailer.with(user:).password_reset.deliver_later
    end

    def set_user_from_token
      @user = User.find_by_token_for!(:password_reset, params[:id])
    rescue StandardError
      redirect_to root_path, error: "That password reset link is invalid"
    end

    def update_params
      params.require(:user).permit(:password, :password_confirmation)
    end
end
