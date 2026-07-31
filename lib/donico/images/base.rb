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
          # A per-matrix image_name is the more specific declaration and must win:
          # merging default_options last used to silently discard it whenever a
          # top-level image_name was also set.
          opts[:name] = matrix.image_name || Donico.config.docker_image_name
          opts = opts.except(:archs).merge(arch: arch) if image_builder == "docker"
          opts
        end

        # Explicit table rather than building a constant name from the config and
        # resolving it dynamically: that indirection needed a vendored constantize
        # and turned any unsupported backend into an opaque NameError.
        IMAGE_CLASSES = {
          "docker" => -> { Donico::Images::Docker },
          "bake"   => -> { Donico::Images::Bake },
        }.freeze

        def build_image_from_matrix(matrix:, arch: nil)
          image_builder = Donico.config.image_builder
          opts          = build_options_for(matrix, image_builder, arch)

          IMAGE_CLASSES.fetch(image_builder).call.new(**opts)
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


      # Every configured tag expanded against the registry, sorted. Sorted here for
      # both backends: bake used to sort while docker kept the donico.yml order, so
      # migrating a repo between backends reshuffled the logs for no reason.
      def prod_tags
        tags.map { |t| prod_tag(t) }.sort
      end


      # The declared build args plus the ones Donico always injects, as a sorted
      # list of "KEY=VALUE". This is the form bake and the HCL template consume.
      #
      # Named raw_/cli_ rather than build_args because a single `build_args` used to
      # mean the flattened CLI form on the docker backend and this list on bake:
      # anything written against Images::Base got one or the other with no clue why.
      def raw_build_args
        (@build_args + base_args).sort
      end


      # The docker CLI form: --build-arg KEY=VALUE --build-arg ...
      def cli_build_args
        raw_build_args.flat_map { |arg| ["--build-arg", arg] }
      end


      private


      # See: https://stackoverflow.com/a/1509939
      # The replacement strings must stay single quoted: in a double quoted string
      # "\1" is the 0x01 control byte, not a backreference, which produced env var
      # names docker silently ignored.
      def underscore(string)
        string.gsub("::", "/")
              .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .tr("-", "_")
              .downcase
      end


      # Tag macros are validated by Config at load time, so format can no longer be
      # reached with an unknown macro or a stray '%'. The $VERBOSE muting that used
      # to wrap this call is gone with it: verified under `ruby -w` that passing
      # extra keys to format emits no warning at all.
      def format_tag(tag, opts = {})
        format(tag, opts)
      end


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
