module Account
  class DeactivationsController < ApplicationController
    before_action :reject_admin_capable_user

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

      # Admin-capable users must NOT self-deactivate via the user-side flow:
      # the last admin doing so would lock the admin panel out of recovery
      # (no remaining User:write capability to reactivate them via Admin API).
      # Plan §13 stipulates "Admin 自己 Deactivate: ブロック". The Admin API side
      # is naturally guarded by `User.non_admin_accounts`; this is the user-side guard.
      def reject_admin_capable_user
        return unless current_user&.can_read?("Admin")

        redirect_to user_path,
                    alert: I18n.t("controllers.account/deactivations.admin_blocked")
      end
  end
end
