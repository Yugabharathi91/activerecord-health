# frozen_string_literal: true

require_relative "../health"

module ActiveRecord
  module Health
    module ConnectionExtension
      def healthy?
        db_config_name = pool.db_config.name
        ActiveRecord::Health.ok?(model: ConnectionModelProxy.new(db_config_name, self))
      end

      def load_pct
        db_config_name = pool.db_config.name
        ActiveRecord::Health.load_pct(model: ConnectionModelProxy.new(db_config_name, self))
      end
    end

    module ModelExtension
      def database_healthy?
        ActiveRecord::Health.ok?(model: self)
      end
    end

    class ConnectionModelProxy
      attr_reader :connection

      def initialize(db_config_name, connection)
        @db_config_name = db_config_name
        @connection = connection
      end

      def connection_db_config
        DbConfigProxy.new(@db_config_name)
      end

      def class
        ActiveRecord::Base
      end
    end

    DbConfigProxy = Struct.new(:name)
  end
end
