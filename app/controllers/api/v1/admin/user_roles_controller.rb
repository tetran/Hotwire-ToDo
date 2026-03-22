module Api
  module V1
    module Admin
      class UserRolesController < ApplicationController
        before_action :set_user
        before_action -> { require_capability!("User", "read") }, only: %i[show]
        before_action -> { require_capability!("User", "write") }, only: %i[update]
        before_action :protect_system_role_assignment, only: %i[update]
        before_action :protect_system_role_removal, only: %i[update]
        before_action :protect_privilege_escalation, only: %i[update]

        def show
          render json: @user.roles.as_json(only: %i[id name description system_role])
        end

        def update
          @user.roles = Role.where(id: role_ids_param)
          render json: @user.roles.as_json(only: %i[id name description system_role])
        end

        private

          def set_user
            @user = User.find_by(id: params[:user_id])
            render json: { error: "Not found" }, status: :not_found unless @user
          end

          def role_ids_param
            params.permit(role_ids: [])[:role_ids] || []
          end

          def protect_system_role_assignment
            return unless Role.exists?(id: role_ids_param, system_role: true)

            render json: { error: "Forbidden" }, status: :forbidden
          end

          def protect_system_role_removal
            current_system_roles = @user.roles.where(system_role: true)
            return unless current_system_roles.exists?

            new_role_ids = role_ids_param.compact_blank.map(&:to_i)
            removed = current_system_roles.reject { |r| new_role_ids.include?(r.id) }
            render json: { error: "Forbidden" }, status: :forbidden if removed.any?
          end

          def protect_privilege_escalation
            new_permission_ids = RolePermission.where(role_id: role_ids_param).pluck(:permission_id).uniq
            return if new_permission_ids.empty?

            admin_permission_ids = current_admin.roles.joins(:permissions).pluck("permissions.id").uniq
            return if (new_permission_ids - admin_permission_ids).empty?

            render json: { error: "Forbidden" }, status: :forbidden
          end
      end
    end
  end
end
