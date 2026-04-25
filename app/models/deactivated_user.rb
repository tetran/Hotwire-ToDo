class DeactivatedUser < ApplicationRecord
  belongs_to :user
  belongs_to :deactivated_by, class_name: "User", optional: true

  validates :original_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :reason, length: { maximum: 500 }, allow_blank: true
  validates :deactivated_at, presence: true
end
