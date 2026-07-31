# frozen_string_literal: true

module Donico
  class Config
    # The supported build backends. This value ends up in a file path handed to
    # Kernel#load and in a constant name, so it can never be taken on trust.
    IMAGE_BUILDERS = %w[docker bake].freeze

    attr_reader :docker_image_name, :docker_registry, :docker_image_tag, :image_builder, :matrix, :commit_linter, :docker_linter

    def initialize(config)
      @docker_image_name = config.fetch("image_name", nil)
      @docker_registry   = config.fetch("registry")
      @docker_image_tag  = config.fetch("tag", nil)
      @image_builder     = validate_image_builder!(config.fetch("image_builder", "docker"))
      @matrix            = config.fetch("matrix", [{}]).map { |m| Matrix.new(m) }

      @commit_linter     = config.fetch("commit_linter", Donico.default_commit_linter)
      @docker_linter     = config.fetch("docker_linter", Donico.default_docker_linter)

      validate_image_names!
      warn_unsupported_secrets
    end

    # When running in CI, use CI_COMMIT_TIMESTAMP as a timestamp to name the build image.
    # When running in dev, generate a timestamp from the current date to name the build image.
    #
    # Memoized so every image of a single run shares one build tag: recomputing
    # Time.now per call let a run straddling midnight build under one tag and look
    # for another at tag time.
    def timestamp
      @timestamp ||= if ENV.key?("CI_COMMIT_TIMESTAMP")
                       Time.parse(ENV.fetch("CI_COMMIT_TIMESTAMP", nil)).strftime("%Y%m%d%H%M%S")
                     else
                       Time.now.strftime("%Y%m%d")
                     end
    end

    # Deduplicated: `dockerfile` defaults to "Dockerfile", so a config with N distros
    # otherwise runs hadolint N times (N image pulls, N containers) on one file.
    # The /app prefix is where the linter container mounts the project.
    def dockerfiles
      matrix.map { |m| "/app/#{m.dockerfile}" }.uniq
    end

    def to_h
      {
        docker_registry:   docker_registry,
        docker_image_name: docker_image_name,
        docker_image_tag:  docker_image_tag,
        image_builder:     image_builder,
        commit_linter:     commit_linter,
        docker_linter:     docker_linter,
        matrix:            matrix.map(&:to_h),
      }
    end

    private

    # The name can come from the top level or from the matrix entry, but it has to
    # come from somewhere: a nil name used to render tags with an empty segment
    # ("/1.0.0/buster:20260731") and a version env var called "_VERSION".
    def validate_image_names!
      return if matrix.all? { |m| m.image_name || docker_image_name }

      raise ConfigError,
            "\nMissing image_name in donico.yml.\n" \
            "Set it at the top level, or on every matrix entry.\n\n"
    end

    # Only the bake template consumes secret_envs / secret_files. The docker
    # backend used to drop them without a word, so the build silently ran without
    # the secret the Dockerfile was written for.
    def warn_unsupported_secrets
      return if image_builder == "bake"
      return if matrix.none? { |m| m.secret_envs.any? || m.secret_files.any? }

      warn "WARNING: secret_envs / secret_files are ignored by the docker backend. Use image_builder: bake to mount them."
    end

    # Without this check a typo failed three different ways depending on which code
    # path ran first: LoadError from load_tasks, RuntimeError from Matrix#matrix_for
    # or NameError from the image class lookup. None of them named the culprit.
    def validate_image_builder!(image_builder)
      return image_builder if IMAGE_BUILDERS.include?(image_builder)

      raise ConfigError,
            "\nUnknown image_builder in donico.yml: #{image_builder.inspect}.\n" \
            "Supported backends: #{IMAGE_BUILDERS.join(', ')}.\n\n"
    end

  end
end
