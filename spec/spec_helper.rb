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
