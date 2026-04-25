module Api
  module V1
    module Admin
      module Users
        class DeactivationsController < Admin::ApplicationController
          before_action -> { require_capability!("User", "write") }

          def create
            target = ::User.non_admin_accounts.active.find_by(id: params[:user_id])
            return render json: { error: "Not Found" }, status: :not_found unless target

            Account::DeactivationService.call(
              user: target,
              performer: current_admin,
              reason: params[:reason],
              self_deactivated: false,
            )
            head :no_content
          rescue ActiveRecord::RecordInvalid => e
            render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
          rescue ActiveRecord::RecordNotUnique
            # Race / double-submit: the user was already deactivated between
            # `User.non_admin_accounts.active.find_by` and the service call
            # (e.g., another admin session, or an immediate retry). Respond
            # with a structured 422 instead of letting it surface as 500.
            render json: { errors: ["User is already deactivated"] }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
