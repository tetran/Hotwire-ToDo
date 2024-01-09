class ApplicationController < ActionController::Base
  include ApplicationHelper
  include SessionsHelper

  protect_from_forgery with: :exception

  around_action :in_time_zone_and_locale, if: :current_user
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

    def in_time_zone_and_locale
      Time.use_zone(current_user.time_zone) do
        I18n.with_locale(current_user.locale) do
          yield
        end
      end
    end
end
