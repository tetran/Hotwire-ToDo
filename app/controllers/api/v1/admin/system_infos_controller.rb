module Api
  module V1
    module Admin
      class SystemInfosController < ApplicationController
        def show
          render json: {
            ruby_version: RUBY_VERSION,
            rails_version: Rails::VERSION::STRING,
            environment: Rails.env,
            database: database_info,
            runtime: runtime_info,
          }
        end

        private

          def database_info
            {
              adapter: ActiveRecord::Base.connection.adapter_name.downcase,
              version: database_version,
            }
          end

          def database_version
            ActiveRecord::Base.connection.select_value("SELECT sqlite_version()")
          rescue StandardError
            nil
          end

          def runtime_info
            {
              memory_mb: memory_mb,
              uptime_seconds: uptime_seconds,
              pool: pool_info,
            }
          end

          def memory_mb
            (`ps -o rss= -p #{Process.pid}`.to_i / 1024.0).round(1)
          rescue StandardError
            nil
          end

          def uptime_seconds
            (Process.clock_gettime(Process::CLOCK_MONOTONIC) - SystemBootTime::MONOTONIC_STARTED_AT).to_i
          end

          def pool_info
            stat = ActiveRecord::Base.connection_pool.stat
            {
              size: stat[:size],
              connections: stat[:connections],
              busy: stat[:busy],
              idle: stat[:idle],
              waiting: stat[:waiting],
            }
          end
      end
    end
  end
end
