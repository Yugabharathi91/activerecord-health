# frozen_string_literal: true

require "test_helper"

class SheddableTest < ActiveRecord::Health::TestCase
  def test_sheddable_executes_block_when_healthy
    cache = MockCache.new
    cache.write("activerecord_health:load_pct:primary", 0.5)

    ActiveRecord::Health.configure do |config|
      config.vcpu_count = 16
      config.threshold = 0.75
      config.cache = cache
    end

    mock_model = MockModel.new("primary")
    result = ActiveRecord::Health.sheddable(model: mock_model) { "executed" }

    assert_equal "executed", result
  end

  def test_sheddable_raises_unhealthy_when_overloaded
    cache = MockCache.new
    cache.write("activerecord_health:load_pct:primary", 0.9)

    ActiveRecord::Health.configure do |config|
      config.vcpu_count = 16
      config.threshold = 0.75
      config.cache = cache
    end

    mock_model = MockModel.new("primary")

    assert_raises(ActiveRecord::Health::Unhealthy) do
      ActiveRecord::Health.sheddable(model: mock_model) { "executed" }
    end
  end

  def test_sheddable_pct_executes_block_when_below_threshold
    cache = MockCache.new
    cache.write("activerecord_health:load_pct:primary", 0.4)

    ActiveRecord::Health.configure do |config|
      config.vcpu_count = 16
      config.cache = cache
    end

    mock_model = MockModel.new("primary")
    result = ActiveRecord::Health.sheddable_pct(pct: 0.5, model: mock_model) { "executed" }

    assert_equal "executed", result
  end

  def test_sheddable_pct_raises_unhealthy_when_above_threshold
    cache = MockCache.new
    cache.write("activerecord_health:load_pct:primary", 0.6)

    ActiveRecord::Health.configure do |config|
      config.vcpu_count = 16
      config.cache = cache
    end

    mock_model = MockModel.new("primary")

    assert_raises(ActiveRecord::Health::Unhealthy) do
      ActiveRecord::Health.sheddable_pct(pct: 0.5, model: mock_model) { "executed" }
    end
  end

  def test_sheddable_pct_executes_block_when_at_threshold
    cache = MockCache.new
    cache.write("activerecord_health:load_pct:primary", 0.5)

    ActiveRecord::Health.configure do |config|
      config.vcpu_count = 16
      config.cache = cache
    end

    mock_model = MockModel.new("primary")
    result = ActiveRecord::Health.sheddable_pct(pct: 0.5, model: mock_model) { "executed" }

    assert_equal "executed", result
  end

  def test_unhealthy_exception_includes_message
    cache = MockCache.new
    cache.write("activerecord_health:load_pct:primary", 0.9)

    ActiveRecord::Health.configure do |config|
      config.vcpu_count = 16
      config.threshold = 0.75
      config.cache = cache
    end

    mock_model = MockModel.new("primary")

    error = assert_raises(ActiveRecord::Health::Unhealthy) do
      ActiveRecord::Health.sheddable(model: mock_model) { "executed" }
    end

    assert_match(/90/, error.message)
  end
end
