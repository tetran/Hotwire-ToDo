class ApplicationController < ActionController::Base
  include ApplicationHelper
  include SessionsHelper

  protect_from_forgery with: :exception

  around_action :in_time_zone_and_locale, if: :logged_in?
  before_action :require_login

  add_flash_types :success, :info, :warning, :error

  private

    def in_time_zone_and_locale
      Time.use_zone(current_user.time_zone) do
        I18n.with_locale(current_user.locale) do
          yield
        end
      end
    end
end
