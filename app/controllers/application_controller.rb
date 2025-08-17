class ApplicationController < ActionController::Base
  include ApplicationHelper

  before_action :require_login
  around_action :in_time_zone_and_locale, if: :logged_in?

  protect_from_forgery with: :exception

  add_flash_types :success, :info, :warning, :error

  helper_method :current_user

  if ENV["BASIC_AUTH_USERNAME"].present? && ENV["BASIC_AUTH_PASSWORD"].present?
    http_basic_authenticate_with name: ENV.fetch("BASIC_AUTH_USERNAME", nil),
                                 password: ENV.fetch("BASIC_AUTH_PASSWORD", nil)
  end

  private

    def in_time_zone_and_locale(&)
      Time.use_zone(current_user.time_zone) do
        I18n.with_locale(current_user.locale, &)
      end
    end

    def sign_in(user)
      session[:user_id] = user.id
    end

    def current_user
      return if session[:user_id].blank?

      if defined?(@current_user)
        @current_user
      else
        @current_user = User.find_by(id: session[:user_id])
      end
    end

    def logged_in?
      current_user.present?
    end

    def require_login
      redirect_to login_url unless logged_in?
    end

    def require_logout
      redirect_to project_url(current_user.inbox_project.id) if logged_in?
    end
end
