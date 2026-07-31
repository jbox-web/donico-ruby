# frozen_string_literal: true

module Donico
  module Images
    class Base

      class << self
        def default_options
          { name: Donico.config.docker_image_name, registry: Donico.config.docker_registry, timestamp: Donico.config.timestamp }
        end

        def build_options_for(matrix, image_builder, arch = nil)
          opts = matrix.to_h.merge(default_options)
          opts[:name] = matrix.image_name if opts[:name].nil?
          opts = opts.except(:archs).merge(arch: arch) if image_builder == "docker"
          opts
        end

        def build_image_from_matrix(matrix:, arch: nil)
          image_builder = Donico.config.image_builder
          opts          = build_options_for(matrix, image_builder, arch)
          klass         = Donico::Utils.constantize("Donico::Images::#{image_builder.capitalize}")
          klass.new(**opts)
        end
      end

      attr_reader :name, :registry, :distro, :version, :timestamp, :tags, :dockerfile, :secret_envs, :secret_files

      # rubocop:disable Metrics/ParameterLists
      def initialize(name:, registry:, distro:, version:, timestamp:, tags:, dockerfile:, build_args:, test_args:, secret_envs:, secret_files:) # rubocop:disable Metrics/MethodLength
        @name         = name
        @registry     = registry
        @distro       = distro
        @version      = version
        @timestamp    = timestamp
        @tags         = tags
        @dockerfile   = dockerfile
        @build_args   = build_args
        @test_args    = test_args
        @secret_envs  = secret_envs
        @secret_files = secret_files
      end
      # rubocop:enable Metrics/ParameterLists


      # Convert docker-in-docker to DOCKER_IN_DOCKER_VERSION
      def version_env_var
        env_var = underscore(name).upcase
        "#{env_var}_VERSION"
      end


      def secrets?
        !@secret_envs.empty? || !@secret_files.empty?
      end


      private


      # See: https://stackoverflow.com/a/1509939
      def underscore(string)
        string.gsub("::", "/")
              .gsub(/([A-Z]+)([A-Z][a-z])/, "\1_\2")
              .gsub(/([a-z\d])([A-Z])/, "\1_\2")
              .tr("-", "_")
              .downcase
      end


      # rubocop:disable Style/RedundantBegin, Style/ParallelAssignment
      def format_tag(tag, opts = {})
        begin
          old_verbose, $VERBOSE = $VERBOSE, nil
          format(tag, opts)
        ensure
          $VERBOSE = old_verbose
        end
      end
      # rubocop:enable Style/RedundantBegin, Style/ParallelAssignment


      def base_args
        ["DISTRO_NAME=#{distro}", "BUILD_DATE=#{timestamp}", "#{version_env_var}=#{version}"]
      end


      # Inspec input names are lowercase, their values are not. Downcasing the whole
      # "KEY=VALUE" pair corrupted every case sensitive value (base64 payloads,
      # tokens, paths) while the build received the correct one, so the test
      # validated something the image never contained.
      def to_inspec_inputs(args)
        args.map do |arg|
          name, value = arg.split("=", 2)
          value.nil? ? name.downcase : "#{name.downcase}=#{value}"
        end
      end

    end
  end
end
