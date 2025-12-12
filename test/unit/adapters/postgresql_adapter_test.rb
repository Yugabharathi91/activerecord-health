# frozen_string_literal: true

require "test_helper"

class PostgreSQLAdapterTest < ActiveRecord::Health::TestCase
  def test_active_session_count_query
    adapter = ActiveRecord::Health::Adapters::PostgreSQLAdapter.new

    expected_query = <<~SQL.squish
      SELECT count(*)
      FROM pg_stat_activity
      WHERE state = 'active'
        AND backend_type = 'client backend'
        AND pid != pg_backend_pid()
    SQL

    assert_equal expected_query, adapter.active_session_count_query
  end

  def test_adapter_name
    adapter = ActiveRecord::Health::Adapters::PostgreSQLAdapter.new

    assert_equal :postgresql, adapter.name
  end
end
