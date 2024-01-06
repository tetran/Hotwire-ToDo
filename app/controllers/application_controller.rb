class ApplicationController < ActionController::Base
  include ApplicationHelper
  include SessionsHelper

  protect_from_forgery with: :exception

  before_action :require_login

  helper_method :current_user, :logged_in?

  add_flash_types :success, :info, :warning, :error

  private

    def require_login
      return if current_user.present?

      redirect_to login_path
    end

    def current_user
      @current_user ||= User.find_by(id: session[:user_id])
    end

    def logged_in?
      current_user.present?
    end

    def require_logout
      redirect_to root_url if current_user.present?
    end
end
