module Authorization
  extend ActiveSupport::Concern

  included do
    before_action :require_admin_access, if: :admin_controller?
    helper_method :can_read?, :can_write?, :can_delete?, :can_manage? if respond_to?(:helper_method)
  end

  class_methods do
    def authorize_resource(resource_type, action = :read)
      before_action -> { authorize_resource!(resource_type, action) }
    end

    def authorize_admin_access
      before_action :require_admin_access
    end
  end

  private

  def require_admin_access
    unless current_user&.can_read?('Admin')
      flash[:error] = I18n.t('authorization.admin_access_denied', default: '管理者権限が必要です')
      redirect_to root_path
    end
  end

  def admin_controller?
    self.class.name.start_with?('Admin::')
  end

  def authorize_resource!(resource_type, action)
    unless current_user&.has_permission?(resource_type, action.to_s)
      handle_authorization_failure(resource_type, action)
    end
  end

  def authorize_read!(resource_type)
    authorize_resource!(resource_type, 'read')
  end

  def authorize_write!(resource_type)
    authorize_resource!(resource_type, 'write')
  end

  def authorize_delete!(resource_type)
    authorize_resource!(resource_type, 'delete')
  end

  def authorize_manage!(resource_type)
    authorize_resource!(resource_type, 'manage')
  end

  def can_read?(resource_type)
    current_user&.can_read?(resource_type)
  end

  def can_write?(resource_type)
    current_user&.can_write?(resource_type)
  end

  def can_delete?(resource_type)
    current_user&.can_delete?(resource_type)
  end

  def can_manage?(resource_type)
    current_user&.can_manage?(resource_type)
  end

  def authorize_user_read!
    unless current_user&.can_read?('User')
      handle_authorization_failure('User', 'read', admin_root_path)
    end
  end

  def authorize_user_write!
    unless current_user&.can_write?('User')
      handle_authorization_failure('User', 'write', admin_root_path)
    end
  end

  def authorize_user_delete!
    unless current_user&.can_delete?('User')
      handle_authorization_failure('User', 'delete', admin_root_path)
    end
  end

  def authorize_admin_read!
    unless current_user&.can_read?('Admin')
      handle_authorization_failure('Admin', 'read', root_path)
    end
  end

  def authorize_admin_write!
    unless current_user&.can_write?('Admin')
      handle_authorization_failure('Admin', 'write', admin_root_path)
    end
  end

  def authorize_admin_delete!
    unless current_user&.can_delete?('Admin')
      handle_authorization_failure('Admin', 'delete', admin_root_path)
    end
  end

  def handle_authorization_failure(resource_type, action, redirect_path = root_path)
    if request.xhr? || request.format.turbo_stream?
      head :forbidden
    else
      flash[:error] = I18n.t(
        'authorization.access_denied',
        resource: I18n.t("resources.#{resource_type.downcase}", default: resource_type),
        action: I18n.t("actions.#{action}", default: action),
        default: "#{resource_type}への#{action}権限がありません"
      )
      redirect_to redirect_path
    end
  end
end
