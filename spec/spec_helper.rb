# frozen_string_literal: true

require "simplecov"
require "rspec"

# Start SimpleCov
# The floor is set just under the current figure: it is a ratchet against silent
# erosion, not a target. Raise it when coverage durably improves.
SimpleCov.start do
  add_filter "spec/"
  minimum_coverage 88
end

require_relative "support/helper"

# Keep the command logging out of the spec output. Donico used to detect RSpec
# itself, which silently disabled logging for any consumer loading RSpec too.
ENV["DONICO_QUIET"] = "true"

# Configure RSpec
RSpec.configure do |config|
  config.include Helper

  # CI_COMMIT_TIMESTAMP switches Config#timestamp between the dev format
  # (%Y%m%d) and the CI one (%Y%m%d%H%M%S), so any example reading a build tag
  # depends on it. Several examples used to delete or set it without restoring
  # it, which under a random order made the outcome depend on the seed: the
  # suite passed locally and failed in CI, where the variable is set.
  #
  # Neutralised and restored around every example. An example that needs the CI
  # format sets it explicitly and gets it cleaned up here.
  config.around do |example|
    previous = ENV.fetch("CI_COMMIT_TIMESTAMP", nil)
    ENV.delete("CI_COMMIT_TIMESTAMP")

    example.run

    previous.nil? ? ENV.delete("CI_COMMIT_TIMESTAMP") : ENV["CI_COMMIT_TIMESTAMP"] = previous
  end

  config.color = true
  config.fail_fast = false

  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # disable monkey patching
  # see: https://relishapp.com/rspec/rspec-core/v/3-8/docs/configuration/zero-monkey-patching-mode
  config.disable_monkey_patching!
end

require "donico"
