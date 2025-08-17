module Admin
  class RolesController < Admin::ApplicationController
    before_action :set_role, only: %i[show edit update destroy]
    before_action :authorize_role_management
    before_action :cannot_delete_system_role, only: :destroy

    def index
      @system_roles = Role.system_roles.includes(:permissions, :users)
      @custom_roles = Role.custom_roles.includes(:permissions, :users)
    end

    def show
      @role_permissions = @role.permissions
      @role_users = @role.users
    end

    def new
      @role = Role.new
    end

    def edit
      return unless @role.system_role?

      flash[:warning] = I18n.t("admin.roles.system_role_warning", default: "システムロールの名前と説明は変更できません")
    end

    def create
      @role = Role.new(role_params)

      if @role.save
        flash[:success] = I18n.t("admin.roles.created_successfully", default: "ロールを作成しました")
        redirect_to admin_role_path(@role)
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      # Prevent editing system role basic info
      update_params = @role.system_role? ? role_params.except(:name, :description) : role_params

      if @role.update(update_params)
        flash[:success] = I18n.t("admin.roles.updated_successfully", default: "ロールを更新しました")
        redirect_to admin_role_path(@role)
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @role.destroy
        flash[:success] = I18n.t("admin.roles.deleted_successfully", default: "ロールを削除しました")
        redirect_to admin_roles_path
      else
        flash[:error] = I18n.t("admin.roles.delete_failed", default: "ロールの削除に失敗しました")
        redirect_to admin_role_path(@role)
      end
    end

    private

      def set_role
        @role = Role.find(params[:id])
      end

      def role_params
        params.expect(role: %i[name description])
      end

      def authorize_role_management
        # All role management operations require Admin:read access to admin area
        authorize_admin_read!

        case action_name
        when "index", "show"
          authorize_user_read! # Role management is part of user management
        when "new", "create", "edit", "update"
          authorize_user_write!
        when "destroy"
          authorize_user_delete!
        end
      end

      def cannot_delete_system_role
        return unless @role.system_role?

        flash[:error] = I18n.t("admin.roles.cannot_delete_system_role", default: "システムロールは削除できません")
        redirect_to admin_role_path(@role)
      end
  end
end
