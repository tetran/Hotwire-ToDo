class Permission < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :resource_type, presence: true
  validates :action, presence: true
  validates :resource_type, uniqueness: { scope: :action }

  RESOURCE_TYPES = %w[User Project Task Comment Admin].freeze
  ACTIONS = %w[read write delete manage].freeze

  validates :resource_type, inclusion: { in: RESOURCE_TYPES }
  validates :action, inclusion: { in: ACTIONS }

  scope :for_resource, ->(resource_type) { where(resource_type: resource_type) }

  def name
    "#{action}_#{resource_type.downcase}"
  end
end
