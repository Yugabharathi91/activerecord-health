# frozen_string_literal: true

module ActiveRecord
  module Health
    class Railtie < Rails::Railtie
      config.after_initialize do
        ActiveRecord::Health.configuration.validate!
      end
    end
  end
end
