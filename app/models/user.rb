class User < ApplicationRecord
  has_secure_password
  normalizes :email, with: -> email { email.strip.downcase }

  has_many :tasks, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, on: [:create, :update_password]
  validates :password, confirmation: true, on: :update_password
end
