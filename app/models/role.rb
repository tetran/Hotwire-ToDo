class Role < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  validates :name, presence: true, uniqueness: true

  scope :system_roles, -> { where(system_role: true) }
  scope :custom_roles, -> { where(system_role: false) }

  def self.admin
    find_by(name: 'admin', system_role: true)
  end

  def self.user_manager
    find_by(name: 'user_manager', system_role: true)
  end

  def self.user_viewer
    find_by(name: 'user_viewer', system_role: true)
  end

  def self.project_manager
    find_by(name: 'project_manager', system_role: true)
  end

  def self.llm_admin
    find_by(name: 'llm_admin', system_role: true)
  end
end