module Api
  module V1
    module Admin
      module Users
        class ReactivationsController < Admin::ApplicationController
          before_action -> { require_capability!("User", "write") }

          def create
            target = ::User.non_admin_accounts.deactivated.find_by(id: params[:user_id])
            return render json: { error: "Not Found" }, status: :not_found unless target

            Account::DeactivationService.reactivate(
              user: target,
              performer: current_admin,
              new_email: params[:new_email],
            )
            head :no_content
          rescue ActiveRecord::RecordInvalid => e
            render json: reactivation_error_body(e), status: :unprocessable_entity
          rescue ActiveRecord::RecordNotFound
            render json: { errors: ["Already reactivated"], already_reactivated: true },
                   status: :unprocessable_entity
          end

          private

            def reactivation_error_body(error)
              body = { errors: error.record.errors.full_messages }
              email_conflict = params[:new_email].blank? && error.record.errors[:email].any?
              body[:original_email_conflict] = true if email_conflict
              body
            end
        end
      end
    end
  end
end
