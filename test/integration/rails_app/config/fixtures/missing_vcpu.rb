# frozen_string_literal: true

ActiveRecord::Health.configure do |config|
  config.cache = ActiveSupport::Cache::MemoryStore.new
end
