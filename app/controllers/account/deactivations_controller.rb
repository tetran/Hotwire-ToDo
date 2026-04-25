module Account
  class DeactivationsController < ApplicationController
    before_action :reject_admin_capable_user

    def new
      @user = current_user
    end

    def create
      @user = current_user
      @user.assign_attributes(deactivation_params)
      return render :new, status: :unprocessable_content unless confirmation_valid?
      return render :new, status: :unprocessable_content unless @user.save
      return render :new, status: :unprocessable_content unless run_deactivation

      reset_session
      redirect_to login_path, notice: I18n.t("controllers.account/deactivations.create.success")
    end

    private

      def deactivation_params
        params.expect(user: %i[reason password_challenge])
      end

      def confirmation_valid?
        return true if params[:confirm_deactivation].present?

        @user.errors.add(:base, I18n.t("controllers.account/deactivations.create.confirmation_required"))
        false
      end

      # Wraps `DeactivationService.call` so race conditions (double-submit, concurrent
      # admin deactivate) surface as a recoverable form error instead of a 500.
      # `RecordNotUnique` fires when the `deactivated_users.user_id` UNIQUE index is
      # already populated for this user; `RecordInvalid` covers any future model-level
      # validation that the service may add.
      def run_deactivation
        Account::DeactivationService.call(
          user: @user,
          performer: @user,
          reason: @user.reason,
          self_deactivated: true,
        )
        true
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        @user.errors.add(:base, I18n.t("controllers.account/deactivations.create.failure"))
        false
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
