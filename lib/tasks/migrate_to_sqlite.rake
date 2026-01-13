# frozen_string_literal: true

namespace :db do
  namespace :migrate_to_sqlite do
    desc "Export data from PostgreSQL to JSON files (uses POSTGRES_* env vars)"
    task export: :environment do
      require "pg"

      # 環境変数からPostgreSQL接続設定を読み込む
      pg_config = {
        host: ENV.fetch("POSTGRES_HOST", "localhost"),
        port: ENV.fetch("POSTGRES_PORT", 5432).to_i,
        user: ENV.fetch("POSTGRES_USERNAME", nil),
        password: ENV.fetch("POSTGRES_PASSWORD", nil),
        dbname: ENV.fetch("POSTGRES_DATABASE", "hobo_production"),
      }

      puts "Connecting to PostgreSQL: #{pg_config[:host]}:#{pg_config[:port]}/#{pg_config[:dbname]}"
      pg_conn = PG.connect(pg_config)

      export_dir = Rails.root.join("tmp/db_export")
      FileUtils.mkdir_p(export_dir)

      # 外部キー依存関係を考慮したテーブル順序
      tables = %w[
        users
        roles
        permissions
        user_roles
        role_permissions
        projects
        project_members
        tasks
        comments
        suggestion_requests
        suggestion_responses
        suggested_tasks
        llm_providers
        llm_models
        sessions
        active_storage_blobs
        active_storage_attachments
        active_storage_variant_records
        action_text_rich_texts
      ]

      tables.each do |table_name|
        puts "Exporting #{table_name}..."
        result = pg_conn.exec("SELECT * FROM #{table_name}")
        records = result.map(&:to_h)
        File.write(
          export_dir.join("#{table_name}.json"),
          records.to_json,
        )
        puts "  -> #{records.count} records exported"
      end

      pg_conn.close
      puts "\nExport completed to #{export_dir}"
    end

    desc "Import data from JSON files to SQLite"
    task import: :environment do
      export_dir = Rails.root.join("tmp/db_export")

      unless export_dir.exist?
        puts "Error: Export directory not found. Run db:migrate_to_sqlite:export first."
        exit 1
      end

      # 外部キー制約を一時的に無効化
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")

      tables = %w[
        users
        roles
        permissions
        user_roles
        role_permissions
        projects
        project_members
        tasks
        comments
        suggestion_requests
        suggestion_responses
        suggested_tasks
        llm_providers
        llm_models
        sessions
        active_storage_blobs
        active_storage_attachments
        active_storage_variant_records
        action_text_rich_texts
      ]

      tables.each do |table_name|
        file_path = export_dir.join("#{table_name}.json")
        next unless file_path.exist?

        puts "Importing #{table_name}..."
        records = JSON.parse(File.read(file_path))

        next if records.empty?

        # バッチインサート
        records.each_slice(1000) do |batch|
          columns = batch.first.keys
          values = batch.map { |r| columns.map { |c| r[c] } }

          ActiveRecord::Base.connection.execute(
            "INSERT INTO #{table_name} (#{columns.join(', ')}) VALUES #{
              values.map { |v| "(#{v.map { |val| ActiveRecord::Base.connection.quote(val) }.join(', ')})" }.join(', ')
            }",
          )
        end

        puts "  -> #{records.count} records imported"
      end

      # 外部キー制約を再有効化
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")

      puts "\nImport completed!"
    end

    desc "Full migration: export from PostgreSQL, switch to SQLite, import"
    task full: :environment do
      puts "=== Step 1: Exporting from PostgreSQL ==="
      puts "Required env vars: POSTGRES_HOST, POSTGRES_USERNAME, POSTGRES_PASSWORD, POSTGRES_DATABASE"
      Rake::Task["db:migrate_to_sqlite:export"].invoke

      puts "\n=== Step 2: Please run: ==="
      puts "  bin/rails db:create db:schema:load"
      puts "  bin/rails db:migrate_to_sqlite:import"
    end
  end
end
