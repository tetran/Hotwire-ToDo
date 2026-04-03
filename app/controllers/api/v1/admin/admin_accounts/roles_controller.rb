module Api
  module V1
    module Admin
      module AdminAccounts
        class RolesController < Admin::ApplicationController
          before_action :set_admin_account
          before_action -> { require_capability!("User", "read") }, only: %i[show]
          before_action -> { require_capability!("User", "write") }, only: %i[update]
          before_action :protect_self_modification, only: %i[update]
          before_action :validate_and_set_roles, only: %i[update]
          before_action :protect_privilege_escalation, only: %i[update]

          def show
            render json: @admin_account.roles.as_json(only: %i[id name description system_role])
          end

          def update
            @admin_account.roles = @roles
            render json: @admin_account.roles.as_json(only: %i[id name description system_role])
          end

          private

            def set_admin_account
              @admin_account = User.admin_accounts.find_by(id: params[:admin_account_id])
              render json: { error: "Not found" }, status: :not_found unless @admin_account
            end

            def protect_self_modification
              return unless @admin_account == current_admin

              render json: { error: "Cannot change your own roles" }, status: :forbidden
            end

            def validate_and_set_roles
              ids = role_ids_param
              if ids.empty?
                return render json: { error: "At least one role is required" },
                              status: :unprocessable_entity
              end

              @roles = Role.where(id: ids)
              unless @roles.count == ids.count
                return render json: { error: "Some roles were not found" },
                              status: :unprocessable_entity
              end

              return if roles_have_admin_access?

              render json: { error: "At least one role with admin access is required" },
                     status: :unprocessable_entity
            end

            def role_ids_param
              params.permit(role_ids: [])[:role_ids]&.compact_blank&.map(&:to_i) || []
            end

            def roles_have_admin_access?
              @roles.joins(:permissions)
                    .exists?(permissions: { resource_type: "Admin", action: %w[read manage] })
            end

            def protect_privilege_escalation
              new_ids = RolePermission.where(role_id: @roles.pluck(:id)).pluck(:permission_id).uniq
              return if new_ids.empty?

              admin_ids = current_admin.roles.joins(:permissions).pluck("permissions.id").uniq
              return if (new_ids - admin_ids).empty?

              render json: { error: "Forbidden" }, status: :forbidden
            end
        end
      end
    end
  end
end
