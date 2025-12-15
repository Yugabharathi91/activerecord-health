# frozen_string_literal: true

ActiveRecord::Health.configure do |config|
  config.vcpu_count = 4
  config.cache = ActiveSupport::Cache::MemoryStore.new
end
