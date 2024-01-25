if ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    # Set traces_sample_rate to 1.0 to capture 100%
    # of transactions for performance monitoring.
    # We recommend adjusting this value in production.
    config.traces_sample_rate = 0.2
    # or
    # config.traces_sampler = lambda do |context|
    #   true
    # end
  end
else
  Rails.logger.warn "----------------------- Sentry DSN not set -----------------------"
end
