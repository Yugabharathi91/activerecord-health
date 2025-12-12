# frozen_string_literal: true

require_relative "lib/activerecord/health/version"

Gem::Specification.new do |spec|
  spec.name = "activerecord-health"
  spec.version = Activerecord::Health::VERSION
  spec.authors = ["Nate Berkopec"]
  spec.email = ["nate.berkopec@speedshop.co"]

  spec.summary = "Database health monitoring for ActiveRecord with automatic load shedding"
  spec.description = "A gem that checks database health by monitoring active session count relative to available vCPUs. Intended for automatic load shedding."
  spec.homepage = "https://github.com/nateberkopec/activerecord-health"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/nateberkopec/activerecord-health"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .github/ .standard.yml])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.0"
  spec.add_dependency "activesupport", ">= 7.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
