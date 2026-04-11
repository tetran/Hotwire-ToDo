ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# Flag system-test runs before Rails' command parser consumes ARGV, so that
# config/database.yml can route them to a separate SQLite file (keeps `bin/rails
# test` and `bin/rails test:system` from stepping on each other's DB state).
ENV["RAILS_SYSTEM_TEST"] = "1" if ARGV.any? { |a| a == "test:system" || a.start_with?("test:system:") }

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
