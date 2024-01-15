class PasswordsController < ApplicationController
  def edit
  end

  def update
    respond_to do |format|
      current_user.assign_attributes(update_params)
      if current_user.save(context: :update_password)
        @message = "Password updated successfully."
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

    def update_params
      params.require(:user).permit(:password, :password_confirmation, :password_challenge)
    end
end
