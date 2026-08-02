# frozen_string_literal: true

require "simplecov"

# Start SimpleCov
# The floor is set just under the current figure: it is a ratchet against silent
# erosion, not a target. Raise it when coverage durably improves.
SimpleCov.start do
  enable_coverage :branch
  formatter SimpleCov::Formatter::MultiFormatter.new([SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::JSONFormatter])
  skip "spec/"

  # Ruby's Coverage only counts the FIRST load of a file (three consecutive loads
  # of the same file leave its counters at 1). Donico.load_tasks re-loads the
  # .rake files for every example, and the example order is random, so a task
  # body counts as covered or not depending on the seed: the reported figure
  # moved between 92.69% and 92.90% run to run, on identical code and tests.
  #
  # Excluded because the number was noise, not a gap: these bodies are one-line
  # delegations to Donico::Tasks::*, and the specs do invoke them and assert on
  # the docker commands they produce.
  skip "lib/donico/rake/tasks/"
end

require_relative "support/helper"

# Keep the command logging out of the spec output. Donico used to detect RSpec
# itself, which silently disabled logging for any consumer loading RSpec too.
ENV["DONICO_QUIET"] = "true"

# Configure RSpec
RSpec.configure do |config|
  config.include Helper

  # Variables the suite must never inherit, because Donico changes behaviour on
  # them and the developer's shell rarely matches CI:
  #
  # * CI_COMMIT_TIMESTAMP switches Config#timestamp between the dev format
  #   (%Y%m%d) and the CI one (%Y%m%d%H%M%S), so any example reading a build tag
  #   depends on it.
  # * GITHUB_TOKEN is declared as a secret_env by the bake fixtures, and the bake
  #   tasks refuse to build when a declared secret is missing.
  # * CI_MERGE_REQUEST_DIFF_BASE_SHA and CI_COMMIT_BEFORE_SHA pick the base of the
  #   range lint-commits hands to commitlint (see Donico::CommitRange). GitLab
  #   exports the second on every push pipeline, including the one that lints
  #   donico itself, so leaving them in place would make the lint-commits
  #   examples pass locally and fail in CI.
  #
  # All have already produced a green local suite and a red CI one. Inheriting
  # them means the machine, not the code, decides the outcome — so the whole
  # environment is snapshotted and restored around every example, and these are
  # cleared. An example that needs one sets it explicitly and gets it cleaned up
  # here.
  volatile_env = %w[CI_COMMIT_TIMESTAMP GITHUB_TOKEN CI_MERGE_REQUEST_DIFF_BASE_SHA CI_COMMIT_BEFORE_SHA].freeze

  config.around do |example|
    snapshot = ENV.to_h
    volatile_env.each { |key| ENV.delete(key) }

    example.run

    ENV.replace(snapshot)
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
