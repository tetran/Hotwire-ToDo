class Admin::PermissionsController < Admin::ApplicationController
  before_action :set_permission, only: [:show]
  before_action :authorize_permission_viewing

  def index
    @permissions_by_resource = Permission.all
                                        .includes(:roles)
                                        .group_by(&:resource_type)
                                        .transform_values { |perms| perms.sort_by(&:action) }
  end

  def show
    @permission_roles = @permission.roles
  end

  private

  def set_permission
    @permission = Permission.find(params[:id])
  end

  def authorize_permission_viewing
    authorize_read!('User')  # Permission viewing is part of user management
  end
end
