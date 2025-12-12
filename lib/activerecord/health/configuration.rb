# frozen_string_literal: true

module ActiveRecord
  module Health
    class ConfigurationError < StandardError; end

    class Configuration
      attr_accessor :vcpu_count, :threshold, :cache, :cache_ttl

      def initialize
        @threshold = 0.75
        @cache_ttl = 60
        @model_configs = {}
      end

      def validate!
        raise ConfigurationError, "vcpu_count must be configured" if vcpu_count.nil?
        raise ConfigurationError, "cache must be configured" if cache.nil?
      end

      def for_model(model, &block)
        if block_given?
          config = ModelConfiguration.new(self)
          block.call(config)
          @model_configs[model] = config
        else
          @model_configs[model] || self
        end
      end

      def max_healthy_sessions
        (vcpu_count * threshold).floor
      end
    end

    class ModelConfiguration
      attr_accessor :vcpu_count
      attr_writer :threshold

      def initialize(parent)
        @parent = parent
      end

      def cache
        @parent.cache
      end

      def cache_ttl
        @parent.cache_ttl
      end

      def threshold
        @threshold || @parent.threshold
      end

      def max_healthy_sessions
        (vcpu_count * threshold).floor
      end
    end
  end
end
