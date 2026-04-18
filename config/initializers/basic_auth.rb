# NOTE: Rack middleware for pilot-phase Basic Auth gating.
# Placed here (rather than app/middleware/) for simplicity while this is the only
# custom middleware. If additional middleware is added, consider relocating to
# app/middleware/ with Zeitwerk autoload.
# Only the /up health-check path is exempted; adding further exemptions requires
# an explicit edit here, not a config change.

require "rack/auth/basic"

class BasicAuthWithHealthcheckExemption
  HEALTHCHECK_PATH = "/up".freeze

  def initialize(app, username, password)
    @app = app
    # NOTE: pass the downstream app (not self) to Rack::Auth::Basic to avoid
    # recursion — Rack::Auth::Basic calls @app on successful auth.
    @basic_auth = Rack::Auth::Basic.new(app, "Restricted") do |u, p|
      ActiveSupport::SecurityUtils.secure_compare(u.to_s, username) &
        ActiveSupport::SecurityUtils.secure_compare(p.to_s, password)
    end
  end

  def call(env)
    return @app.call(env) if env["PATH_INFO"] == HEALTHCHECK_PATH

    @basic_auth.call(env)
  end
end

if ENV["BASIC_AUTH_USERNAME"].present? && ENV["BASIC_AUTH_PASSWORD"].present?
  Rails.application.config.middleware.insert_after(
    ActionDispatch::HostAuthorization,
    BasicAuthWithHealthcheckExemption,
    ENV.fetch("BASIC_AUTH_USERNAME"),
    ENV.fetch("BASIC_AUTH_PASSWORD"),
  )
end
