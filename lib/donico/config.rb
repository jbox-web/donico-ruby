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
    end

    # When running in CI, use CI_COMMIT_TIMESTAMP as a timestamp to name the build image.
    # When running in dev, generate a timestamp from the current date to name the build image.
    def timestamp
      if ENV.key?("CI_COMMIT_TIMESTAMP")
        date = Time.parse(ENV.fetch("CI_COMMIT_TIMESTAMP", nil))
        date.strftime("%Y%m%d%H%M%S")
      else
        date = Time.now
        date.strftime("%Y%m%d")
      end
    end

    def dockerfiles
      matrix.collect { |m| "/app/#{m.dockerfile}" }
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
