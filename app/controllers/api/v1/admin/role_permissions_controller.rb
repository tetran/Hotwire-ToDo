module Api
  module V1
    module Admin
      class RolePermissionsController < ApplicationController
        before_action :set_role
        before_action :require_manage_access, only: %i[update]
        before_action :protect_system_role, only: %i[update]
        before_action :protect_permission_escalation, only: %i[update]

        def show
          render json: @role.permissions.as_json(only: %i[id resource_type action description])
        end

        def update
          @role.permissions = Permission.where(id: permission_ids_param)
          render json: @role.permissions.as_json(only: %i[id resource_type action description])
        end

        private

          def set_role
            @role = Role.find_by(id: params[:role_id])
            render json: { error: "Not found" }, status: :not_found unless @role
          end

          def permission_ids_param
            params.permit(permission_ids: [])[:permission_ids] || []
          end

          def protect_permission_escalation
            return if current_admin.can_grant_permissions?(permission_ids_param)

            render json: { error: "Forbidden" }, status: :forbidden
          end
      end
    end
  end
end
