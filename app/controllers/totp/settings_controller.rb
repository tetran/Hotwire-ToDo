module Totp
  class SettingsController < ApplicationController
    before_action :set_totp, only: %i[show create]

    def show
      set_totp_url
    end

    def create
      respond_to do |format|
        if @totp.verify(params[:code])
          current_user.update!(totp_enabled: true)
          @message = t("controllers.totp/settings.create.success")
          format.turbo_stream
        else
          set_totp_url
          @err_message = t("controllers.totp/settings.create.invalid_code")
          format.html { render :show, status: :unprocessable_content }
        end
      end
    end

    def update
      respond_to do |format|
        current_user.regenerate_totp_secret!

        @message = t("controllers.totp/settings.update.success")
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
