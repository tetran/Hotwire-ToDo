module Projects
  class MembersController < ApplicationController
    include ProjectDependent

    def create
      @user = User.find_by(email: params[:email])
      respond_to do |format|
        if @user.present? && @project.members.exclude?(@user)
          @project.members << @user
          format.turbo_stream
        else
          format.turbo_stream do
            view = { partial: "shared/simple_error_message", locals: { message: "Failed" } }
            render turbo_stream: turbo_stream.replace("project_member_error", view),
                   status: :unprocessable_content
          end
        end
      end
    end

    def destroy
      @user = User.find(params[:id])
      respond_to do |format|
        @project.members.destroy(@user)

        if @user == current_user
          # 自身が去った場合はinboxにリダイレクト
          format.html { redirect_to project_url(current_user.inbox_project.id) }
        else
          format.turbo_stream
        end
      end
    end
  end
end
