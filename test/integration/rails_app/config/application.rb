# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_record/railtie"
require "activerecord/health"

module RailsApp
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.logger = Logger.new(nil)
  end
end
