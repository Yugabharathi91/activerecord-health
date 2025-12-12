# frozen_string_literal: true

require "test_helper"

class MySQLAdapterTest < ActiveRecord::Health::TestCase
  def test_active_session_count_query_for_mysql_8_0_22_plus
    adapter = ActiveRecord::Health::Adapters::MySQLAdapter.new("8.0.22")

    expected_query = <<~SQL.squish
      SELECT COUNT(*)
      FROM performance_schema.processlist
      WHERE COMMAND != 'Sleep'
        AND ID != CONNECTION_ID()
        AND USER NOT IN ('event_scheduler', 'system user')
    SQL

    assert_equal expected_query, adapter.active_session_count_query
  end

  def test_active_session_count_query_for_mysql_8_0_21
    adapter = ActiveRecord::Health::Adapters::MySQLAdapter.new("8.0.21")

    expected_query = <<~SQL.squish
      SELECT COUNT(*)
      FROM information_schema.processlist
      WHERE Command != 'Sleep'
        AND ID != CONNECTION_ID()
        AND User NOT IN ('event_scheduler', 'system user')
        AND Command NOT IN ('Binlog Dump', 'Binlog Dump GTID')
    SQL

    assert_equal expected_query, adapter.active_session_count_query
  end

  def test_active_session_count_query_for_mysql_5
    adapter = ActiveRecord::Health::Adapters::MySQLAdapter.new("5.7.35")

    expected_query = <<~SQL.squish
      SELECT COUNT(*)
      FROM information_schema.processlist
      WHERE Command != 'Sleep'
        AND ID != CONNECTION_ID()
        AND User NOT IN ('event_scheduler', 'system user')
        AND Command NOT IN ('Binlog Dump', 'Binlog Dump GTID')
    SQL

    assert_equal expected_query, adapter.active_session_count_query
  end

  def test_active_session_count_query_for_mariadb
    adapter = ActiveRecord::Health::Adapters::MySQLAdapter.new("10.5.12-MariaDB")

    expected_query = <<~SQL.squish
      SELECT COUNT(*)
      FROM information_schema.processlist
      WHERE Command != 'Sleep'
        AND ID != CONNECTION_ID()
        AND User NOT IN ('event_scheduler', 'system user')
        AND Command NOT IN ('Binlog Dump', 'Binlog Dump GTID')
    SQL

    assert_equal expected_query, adapter.active_session_count_query
  end

  def test_adapter_name
    adapter = ActiveRecord::Health::Adapters::MySQLAdapter.new("8.0.22")

    assert_equal :mysql, adapter.name
  end

  def test_uses_performance_schema_returns_true_for_mysql_8_0_22_plus
    adapter = ActiveRecord::Health::Adapters::MySQLAdapter.new("8.0.22")

    assert adapter.uses_performance_schema?
  end

  def test_uses_performance_schema_returns_true_for_mysql_8_1
    adapter = ActiveRecord::Health::Adapters::MySQLAdapter.new("8.1.0")

    assert adapter.uses_performance_schema?
  end

  def test_uses_performance_schema_returns_false_for_mysql_8_0_21
    adapter = ActiveRecord::Health::Adapters::MySQLAdapter.new("8.0.21")

    refute adapter.uses_performance_schema?
  end

  def test_uses_performance_schema_returns_false_for_mariadb
    adapter = ActiveRecord::Health::Adapters::MySQLAdapter.new("10.5.12-MariaDB")

    refute adapter.uses_performance_schema?
  end
end
