# frozen_string_literal: true

module ActiveRecord
  module Health
    module Adapters
      class PostgreSQLAdapter
        def self.build(_connection)
          new
        end

        def name
          :postgresql
        end

        def active_session_count_query
          <<~SQL.squish
            SELECT count(*)
            FROM pg_stat_activity
            WHERE state = 'active'
              AND backend_type = 'client backend'
              AND pid != pg_backend_pid()
          SQL
        end

        def execute_with_timeout(connection, query, timeout)
          connection.transaction do
            connection.execute("SET LOCAL statement_timeout = '#{timeout}s'")
            connection.select_value(query)
          end
        end
      end
    end
  end
end
