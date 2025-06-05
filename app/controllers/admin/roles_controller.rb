class Admin::RolesController < Admin::ApplicationController
  before_action :set_role, only: [:show, :edit, :update, :destroy, :assign_permissions, :update_permissions]
  before_action :authorize_role_management

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

  def create
    @role = Role.new(role_params)
    
    if @role.save
      flash[:success] = I18n.t('admin.roles.created_successfully', default: 'ロールを作成しました')
      redirect_to admin_role_path(@role)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    if @role.system_role?
      flash[:warning] = I18n.t('admin.roles.system_role_warning', default: 'システムロールの名前と説明は変更できません')
    end
  end

  def update
    # Prevent editing system role basic info
    update_params = @role.system_role? ? role_params.except(:name, :description) : role_params
    
    if @role.update(update_params)
      flash[:success] = I18n.t('admin.roles.updated_successfully', default: 'ロールを更新しました')
      redirect_to admin_role_path(@role)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @role.system_role?
      flash[:error] = I18n.t('admin.roles.cannot_delete_system_role', default: 'システムロールは削除できません')
      redirect_to admin_role_path(@role)
      return
    end

    if @role.destroy
      flash[:success] = I18n.t('admin.roles.deleted_successfully', default: 'ロールを削除しました')
      redirect_to admin_roles_path
    else
      flash[:error] = I18n.t('admin.roles.delete_failed', default: 'ロールの削除に失敗しました')
      redirect_to admin_role_path(@role)
    end
  end

  def assign_permissions
    @available_permissions = Permission.all.group_by(&:resource_type)
    @role_permissions = @role.permissions
  end

  def update_permissions
    permission_ids = params[:permission_ids] || []
    @role.permission_ids = permission_ids
    
    flash[:success] = I18n.t('admin.roles.permissions_updated', default: '権限を更新しました')
    redirect_to admin_role_path(@role)
  rescue => e
    flash[:error] = I18n.t('admin.roles.permissions_update_failed', default: '権限の更新に失敗しました')
    redirect_to assign_permissions_admin_role_path(@role)
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:name, :description)
  end

  def authorize_role_management
    case action_name
    when 'index', 'show'
      authorize_read!('User')  # Role management is part of user management
    when 'new', 'create', 'edit', 'update', 'assign_permissions', 'update_permissions'
      authorize_write!('User')
    when 'destroy'
      authorize_delete!('User')
    end
  end
end