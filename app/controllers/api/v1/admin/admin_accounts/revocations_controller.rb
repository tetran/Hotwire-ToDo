module Api
  module V1
    module Admin
      module AdminAccounts
        class RevocationsController < Admin::ApplicationController
          before_action -> { require_capability!("User", "write") }
          before_action :set_admin_account
          before_action :set_admin_roles
          before_action :protect_revocation_escalation

          def create
            if @admin_account == current_admin
              render json: { error: "Cannot revoke your own admin access" }, status: :forbidden
              return
            end

            @admin_account.user_roles.where(role_id: @admin_roles.pluck(:id)).destroy_all
            head :no_content
          end

          private

            def set_admin_account
              @admin_account = User.admin_accounts.find_by(id: params[:admin_account_id])
              render json: { error: "Not found" }, status: :not_found unless @admin_account
            end

            def set_admin_roles
              return unless @admin_account

              @admin_roles = @admin_account.roles.joins(:permissions).where(
                permissions: { resource_type: "Admin", action: %w[read manage] },
              ).distinct
            end

            def protect_revocation_escalation
              return unless @admin_roles

              target_ids = RolePermission.where(role_id: @admin_roles).pluck(:permission_id).uniq
              admin_ids = current_admin.roles.joins(:permissions).pluck("permissions.id").uniq
              return if (target_ids - admin_ids).empty?

              render json: { error: "Forbidden" }, status: :forbidden
            end
        end
      end
    end
  end
end
