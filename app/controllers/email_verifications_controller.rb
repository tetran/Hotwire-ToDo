class EmailVerificationsController < ApplicationController
  skip_before_action :require_login, only: [:show]
  before_action :set_user, only: [:show]

  def show
    @user.update! verified: true
    redirect_to root_path, success: "Your email has been verified!"
  end

  private

    def set_user
      @user = User.find_by_token_for!(:email_verification, params[:sid])
    rescue StandardError
      redirect_to root_path, error: "That email verification link is invalid"
    end
end
