class EmailsController < ApplicationController
  include VerifyEmail

  def edit
  end

  def update
    respond_to do |format|
      if current_user.update(email_params.merge(verified: false))
        @message = current_user.email_previously_changed? ? "Email updated successfully." : ""
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  private

    def email_params
      params.require(:user).permit(:email, :password_challenge)
    end
end
