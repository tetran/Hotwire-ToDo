# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  def email_verification
    UserMailer.with(user: User.first).email_verification
  end
end
