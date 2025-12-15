# frozen_string_literal: true

require "test_helper"
require "open3"

class RailsIntegrationTest < Minitest::Test
  def test_boots_successfully_with_valid_initializer_configuration
    output, status = run_rails_runner("puts ActiveRecord::Health.configuration.vcpu_count")

    assert status.success?, "Expected success but got: #{output}"
    assert_equal "4", output.strip
  end

  def test_configuration_from_initializer_is_applied
    output, status = run_rails_runner(<<~RUBY)
      puts ActiveRecord::Health.configuration.vcpu_count
      puts ActiveRecord::Health.configuration.cache.class.name
    RUBY

    assert status.success?, "Expected success but got: #{output}"
    lines = output.strip.split("\n")
    assert_equal "4", lines[0]
    assert_equal "ActiveSupport::Cache::MemoryStore", lines[1]
  end

  def test_raises_configuration_error_when_vcpu_count_missing
    output, status = run_rails_runner("puts 'ok'", fixture: "missing_vcpu")

    refute status.success?
    assert_match(/vcpu_count must be configured/, output)
  end

  def test_raises_configuration_error_when_cache_missing
    output, status = run_rails_runner("puts 'ok'", fixture: "missing_cache")

    refute status.success?
    assert_match(/cache must be configured/, output)
  end

  def test_configuration_defaults_are_preserved
    output, status = run_rails_runner(<<~RUBY)
      puts ActiveRecord::Health.configuration.threshold
      puts ActiveRecord::Health.configuration.cache_ttl
    RUBY

    assert status.success?, "Expected success but got: #{output}"
    lines = output.strip.split("\n")
    assert_equal "0.75", lines[0]
    assert_equal "60", lines[1]
  end

  private

  def run_rails_runner(code, fixture: "valid")
    rails_app_path = File.expand_path("rails_app", __dir__)

    env = {
      "BUNDLE_GEMFILE" => File.expand_path("../../Gemfile", __dir__),
      "HEALTH_CONFIG_FIXTURE" => fixture
    }
    cmd = "bundle exec ruby -e \"require '#{rails_app_path}/config/environment'; #{code.gsub('"', '\\"').gsub("\n", "; ")}\""

    Open3.capture2e(env, cmd, chdir: rails_app_path)
  end
end
