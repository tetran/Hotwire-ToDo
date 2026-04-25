module Account
  class DeactivationsController < ApplicationController
    def new
      @user = current_user
    end

    def create
      @user = current_user
      @user.assign_attributes(deactivation_params)

      if @user.save
        Account::DeactivationService.call(
          user: @user,
          performer: @user,
          reason: @user.reason,
          self_deactivated: true,
        )
        reset_session
        redirect_to login_path, notice: I18n.t("controllers.account/deactivations.create.success")
      else
        render :new, status: :unprocessable_content
      end
    end

    private

      def deactivation_params
        params.expect(user: %i[reason password_challenge])
      end
  end
end
