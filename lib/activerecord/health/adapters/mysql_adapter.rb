# frozen_string_literal: true

module ActiveRecord
  module Health
    module Adapters
      class MySQLAdapter
        PERFORMANCE_SCHEMA_MIN_VERSION = Gem::Version.new("8.0.22")

        attr_reader :version_string

        def initialize(version_string)
          @version_string = version_string
        end

        def name
          :mysql
        end

        def active_session_count_query
          uses_performance_schema? ? performance_schema_query : information_schema_query
        end

        def uses_performance_schema?
          !mariadb? && mysql_version >= PERFORMANCE_SCHEMA_MIN_VERSION
        end

        private

        def mariadb?
          version_string.downcase.include?("mariadb")
        end

        def mysql_version
          Gem::Version.new(version_string.split("-").first)
        end

        def performance_schema_query
          <<~SQL.squish
            SELECT COUNT(*)
            FROM performance_schema.processlist
            WHERE COMMAND != 'Sleep'
              AND ID != CONNECTION_ID()
              AND USER NOT IN ('event_scheduler', 'system user')
          SQL
        end

        def information_schema_query
          <<~SQL.squish
            SELECT COUNT(*)
            FROM information_schema.processlist
            WHERE Command != 'Sleep'
              AND ID != CONNECTION_ID()
              AND User NOT IN ('event_scheduler', 'system user')
              AND Command NOT IN ('Binlog Dump', 'Binlog Dump GTID')
          SQL
        end
      end
    end
  end
end
