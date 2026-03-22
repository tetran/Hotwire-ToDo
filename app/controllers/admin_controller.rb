class AdminController < ApplicationController
  skip_before_action :require_login
  before_action :require_admin_session

  def index
    render layout: "admin"
  end

  private

    def require_admin_session
      return if request.path.start_with?("/admin/login")
      return if admin_logged_in?

      redirect_to "/admin/login"
    end
end
