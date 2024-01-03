class User < ApplicationRecord
  has_secure_password
  normalizes :email, with: -> email { email.strip.downcase }

  has_many :tasks, dependent: :destroy
end
