class EmailsController < ApplicationController
  def edit
  end

  def update
    respond_to do |format|
      if current_user.update(email_params.merge(verified: false))
        @message = current_user.email_previously_changed? ? "Email updated successfully." : ""
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

    def email_params
      params.require(:user).permit(:email, :password_challenge)
    end

    def send_email_verification
      UserMailer.with(user: current_user).email_verification.deliver_later
    end
end
