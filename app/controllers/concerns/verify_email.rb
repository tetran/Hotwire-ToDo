# frozen_string_literal: true

module VerifyEmail
  extend ActiveSupport::Concern

  def send_email_verification(user = current_user)
    UserMailer.with(user:).email_verification.deliver_later
  end
end
