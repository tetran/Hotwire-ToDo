class User < ApplicationRecord
  has_secure_password

  generates_token_for :email_verification, expires_in: 15.minutes { email }
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt.last(10)
  end
  generates_token_for :totp_verification, expires_in: 15.minutes { email }

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [120, 120], preprocessed: true
    attachable.variant :icon, resize_to_limit: [40, 40], preprocessed: true
  end

  normalizes :email, with: ->(email) { email.strip.downcase }

  has_many :comments, dependent: :restrict_with_error
  has_many :project_members, dependent: :restrict_with_error
  has_many :projects, through: :project_members
  # 参加しているprojectsのタスクすべて
  has_many :tasks, through: :projects
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assignee_id, dependent: :nullify, inverse_of: :assignee
  # inboxプロジェクト: owner_idが自分で、dedicatedがtrueのプロジェクト。各ユーザーに1つだけ存在する。
  has_one :inbox_project, lambda {
    where(dedicated: true)
  }, class_name: "Project", foreign_key: :owner_id, dependent: :destroy, inverse_of: :owner

  # ロールベース認可
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  before_validation :generate_totp_secret, on: :create
  after_create :create_inbox_project

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, on: %i[create update_password]
  validates :password, confirmation: true, on: :update_password

  def participating_projects
    # Inboxを最初に表示するため`dedicated`の降順でソート
    projects.unarchived.order({ dedicated: :desc }, :created_at)
  end

  def user_name
    name.presence || email.split("@").first
  end

  def regenerate_totp_secret!
    generate_totp_secret
    self.totp_enabled = false
    save!
  end

  # ロールベース認可メソッド
  def admin?
    roles.exists?(name: "admin", system_role: true)
  end

  def has_permission?(resource_type, action)
    roles.joins(:permissions)
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

  def force_destroy
    comments.destroy_all
    project_members.destroy_all
    destroy
  end

  private

    def generate_totp_secret
      self.totp_secret = ROTP::Base32.random
    end

    def create_inbox_project
      Project.create!(name: "inbox", owner_id: id, dedicated: true)
    end
end
