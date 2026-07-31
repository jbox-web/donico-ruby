# frozen_string_literal: true

module Donico
  # Raised when donico.yml is malformed or holds an unsupported value.
  # Always carries a message the end user can act on without reading Donico's source.
  class ConfigError < StandardError; end
end
