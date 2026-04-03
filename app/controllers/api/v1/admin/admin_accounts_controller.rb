module Api
  module V1
    module Admin
      class AdminAccountsController < ApplicationController
        before_action :set_admin_account, only: %i[destroy]
        before_action -> { require_capability!("Admin", "read") }, only: %i[index]
        before_action -> { require_capability!("User", "delete") }, only: %i[destroy]

        def index
          admin_accounts = User.admin_accounts.includes(:roles).search(params[:q]).order(:id)
          render json: admin_accounts.as_json(
            only: %i[id email name created_at updated_at],
            include: { roles: { only: %i[id name] } },
          )
        end

        def destroy
          if @admin_account == current_admin
            render json: { error: "Cannot delete yourself" }, status: :forbidden
            return
          end

          @admin_account.force_destroy
          head :no_content
        end

        private

          def set_admin_account
            @admin_account = User.admin_accounts.find_by(id: params[:id])
            render json: { error: "Not found" }, status: :not_found unless @admin_account
          end
      end
    end
  end
end
