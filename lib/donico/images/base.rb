# frozen_string_literal: true

module Donico
  module Images
    class Base

      attr_reader :name, :registry, :arch, :distro, :version, :timestamp, :tags

      # rubocop:disable Metrics/ParameterLists:
      def initialize(name:, registry:, arch:, distro:, version:, timestamp:, tags:)
        @name      = name
        @registry  = registry
        @arch      = arch
        @distro    = distro
        @version   = version
        @timestamp = timestamp
        @tags      = tags
      end
      # rubocop:enable Metrics/ParameterLists:


      private


      # Convert docker-in-docker to DOCKER_IN_DOCKER_VERSION
      def version_env_var
        env_var = underscore(name).upcase
        "#{env_var}_VERSION"
      end


      # See: https://stackoverflow.com/a/1509939
      def underscore(string)
        string.gsub(/::/, "/")
              .gsub(/([A-Z]+)([A-Z][a-z])/, "\1_\2")
              .gsub(/([a-z\d])([A-Z])/, "\1_\2")
              .tr("-", "_")
              .downcase
      end

    end
  end
end
