class User < ApplicationRecord
  has_secure_password

  generates_token_for :email_verification, expires_in: 15.minutes { email }
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt.last(10)
  end
  generates_token_for :totp_verification, expires_in: 15.minutes { email }

  has_one_attached :avatar

  normalizes :email, with: -> email { email.strip.downcase }

  has_many :comments, dependent: :restrict_with_error
  has_many :project_members, dependent: :restrict_with_error
  has_many :projects, through: :project_members
  # 参加しているprojectsのタスクすべて
  has_many :tasks, through: :projects
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assignee_id, dependent: :nullify
  # inboxプロジェクト: owner_idが自分で、dedicatedがtrueのプロジェクト。各ユーザーに1つだけ存在する。
  has_one :inbox_project, -> { where(dedicated: true) }, class_name: "Project", foreign_key: :owner_id, dependent: :destroy

  before_validation :generate_totp_secret, on: :create
  after_create :create_inbox_project

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, on: [:create, :update_password]
  validates :password, confirmation: true, on: :update_password

  def user_name
    name.presence || email.split("@").first
  end

  def regenerate_totp_secret!
    generate_totp_secret
    self.totp_enabled = false
    save!
  end

  private

    def generate_totp_secret
      self.totp_secret = ROTP::Base32.random
    end

    def create_inbox_project
      Project.create!(name: "inbox", owner_id: id, dedicated: true)
    end
end
