class ApplicationMailer < ActionMailer::Base
  default from: "noreply@#{ENV.fetch('APP_HOST', nil)}"
  layout "mailer"
end
