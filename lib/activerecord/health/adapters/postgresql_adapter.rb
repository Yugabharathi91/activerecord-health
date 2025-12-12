# frozen_string_literal: true

module ActiveRecord
  module Health
    module Adapters
      class PostgreSQLAdapter
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
      end
    end
  end
end
