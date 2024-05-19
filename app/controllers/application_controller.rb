class ApplicationController < ActionController::Base
  include ApplicationHelper
  include SessionsHelper

  before_action :require_login
  around_action :in_time_zone_and_locale, if: :logged_in?

  protect_from_forgery with: :exception

  add_flash_types :success, :info, :warning, :error

  if ENV["BASIC_AUTH_USERNAME"].present? && ENV["BASIC_AUTH_PASSWORD"].present?
    http_basic_authenticate_with name: ENV["BASIC_AUTH_USERNAME"], password: ENV["BASIC_AUTH_PASSWORD"]
  end

  private

    def in_time_zone_and_locale
      Time.use_zone(current_user.time_zone) do
        I18n.with_locale(current_user.locale) do
          yield
        end
      end
    end
end
