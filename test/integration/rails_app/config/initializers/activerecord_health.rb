# frozen_string_literal: true

fixture = ENV.fetch("HEALTH_CONFIG_FIXTURE", "valid")
require_relative "../fixtures/#{fixture}"
