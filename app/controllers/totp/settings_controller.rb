module Totp
  class SettingsController < ApplicationController
    before_action :set_totp, only: [:show, :create]

    def show
      set_totp_url
    end

    def create
      respond_to do |format|
        if @totp.verify(params[:code])
          current_user.update!(totp_enabled: true)
          @message = "Enable two-factor authentication successfully."
          format.turbo_stream
        else
          set_totp_url
          @err_message = "Invalid code"
          format.html { render :show, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        current_user.regenerate_totp_secret!

        @message = "Your two-factor authentication setting has been reset successfully."
        format.turbo_stream
      end
    end

    private

      def set_totp
        @totp = ROTP::TOTP.new(current_user.totp_secret, issuer: "Hobo Todo")
      end

      def set_totp_url
        @provisioning_uri = provisioning_uri
        @qr_code = RQRCode::QRCode.new(@provisioning_uri)
      end

      def provisioning_uri
        @totp.provisioning_uri(current_user.email)
      end
  end
end
