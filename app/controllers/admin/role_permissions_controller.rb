module Admin
  class RolePermissionsController < Admin::ApplicationController
    before_action :set_role, only: %i[show update]
    before_action :authorize_role_permission_management

    # GET /admin/roles/:role_id/permissions
    def show
      @available_permissions = Permission.all.group_by(&:resource_type)
      @assigned_permissions = @role.permissions
    end

    # PATCH /admin/roles/:role_id/permissions
    def update
      permission_ids = params[:permission_ids] || []
      @role.permissions = Permission.where(id: permission_ids)

      if @role.save
        redirect_to admin_role_path(@role), notice: "ロールの権限が更新されました。"
      else
        redirect_to admin_role_path(@role), alert: "権限の更新に失敗しました。"
      end
    end

    private

      def set_role
        @role = Role.find(params[:role_id])
      end

      def authorize_role_permission_management
        # All role permission management operations require Admin:read access to admin area
        authorize_admin_read!

        case action_name
        when "show"
          authorize_user_read! # Role management is part of user management
        when "update"
          authorize_user_write!
        end
      end
  end
end
