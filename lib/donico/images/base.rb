# frozen_string_literal: true

module Donico
  module Images
    class Base

      attr_reader :name, :registry, :distro, :version, :timestamp, :tags, :dockerfile

      # rubocop:disable Metrics/ParameterLists
      def initialize(name:, registry:, distro:, version:, timestamp:, tags:, dockerfile:, build_args:, test_args:)
        @name       = name
        @registry   = registry
        @distro     = distro
        @version    = version
        @timestamp  = timestamp
        @tags       = tags
        @dockerfile = dockerfile
        @build_args = build_args
        @test_args  = test_args
      end
      # rubocop:enable Metrics/ParameterLists


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
