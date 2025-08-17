module Totp
  class ChallengesController < ApplicationController
    skip_before_action :require_login, only: %i[new create]
    before_action :set_user_from_token, only: :create

    def new
      @token = params[:token]
    end

    def create
      @totp = ROTP::TOTP.new(@user.totp_secret, issuer: "Hobo Todo")

      if @totp.verify(params[:code])
        sign_in(@user)
        redirect_to project_url(@user.inbox_project.id), success: "Logged in!"
      else
        @token = @user.generate_token_for(:totp_verification)
        @err_message = "Invalid code"
        render :new, status: :unprocessable_content
      end
    end

    private

      def set_user_from_token
        @user = User.find_by_token_for!(:totp_verification, params[:token])
      rescue StandardError
        redirect_to root_path, error: "That password reset link is invalid"
      end
  end
end
