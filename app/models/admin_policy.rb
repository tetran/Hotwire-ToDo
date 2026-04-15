class AdminPolicy
  def initialize(user)
    @user = user
  end

  def admin?
    @user.roles.exists?(name: "admin", system_role: true)
  end

  def has_permission?(resource_type, action)
    @user.roles.joins(:permissions)
         .exists?(permissions: { resource_type: resource_type, action: action })
  end

  def can_read?(resource_type)
    has_permission?(resource_type, "read") || has_permission?(resource_type, "manage")
  end

  def can_write?(resource_type)
    has_permission?(resource_type, "write") || has_permission?(resource_type, "manage")
  end

  def can_delete?(resource_type)
    has_permission?(resource_type, "delete") || has_permission?(resource_type, "manage")
  end

  def can_manage?(resource_type)
    has_permission?(resource_type, "manage")
  end

  def owned_permission_ids
    @user.roles.joins(:permissions).distinct.pluck("permissions.id")
  end

  def can_grant_permissions?(permission_ids)
    ids = Array(permission_ids).compact_blank.map(&:to_i)
    (ids - owned_permission_ids).empty?
  end
end
