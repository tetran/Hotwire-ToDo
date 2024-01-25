class ApplicationMailer < ActionMailer::Base
  default from: "noreply@#{ENV["APP_HOST"]}"
  layout "mailer"
end
