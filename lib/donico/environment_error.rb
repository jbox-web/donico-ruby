# frozen_string_literal: true

module Donico
  # Raised when donico.yml is valid but the environment it runs in cannot satisfy
  # it — a declared secret whose variable is unset, a secret file that is missing.
  # Distinct from ConfigError: nothing needs fixing in the config, the shell does.
  class EnvironmentError < StandardError; end
end
