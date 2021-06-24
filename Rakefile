# frozen_string_literal: true

require "bundler/gem_tasks"

# Don't load RSpec in release mode
unless ENV["DONICO_RELEASE"] == "true"
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
end
