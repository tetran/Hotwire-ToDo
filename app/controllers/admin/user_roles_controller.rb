module Admin
  class UserRolesController < Admin::ApplicationController
    before_action :set_user, only: %i[show update]
    before_action :authorize_user_role_management

    # GET /admin/users/:user_id/roles
    def show
      @available_roles = Role.all
      @assigned_roles = @user.roles
    end

    # PATCH /admin/users/:user_id/roles
    def update
      role_ids = params[:role_ids] || []
      @user.roles = Role.where(id: role_ids)

      if @user.save
        redirect_to admin_user_path(@user), notice: "ユーザーのロールが更新されました。"
      else
        redirect_to admin_user_path(@user), alert: "ロールの更新に失敗しました。"
      end
    end

    private

      def set_user
        @user = User.find(params[:user_id])
      end

      def authorize_user_role_management
        # All user role management operations require Admin:read access to admin area
        authorize_admin_read!

        case action_name
        when "show"
          authorize_user_read!
        when "update"
          authorize_user_write!
        end
      end
  end
end
