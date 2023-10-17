# frozen_string_literal: true

module Donico
  class Config
    attr_reader :docker_image_name, :docker_registry, :docker_image_tag, :image_builder, :earthly_version, :matrix, :commit_linter, :docker_linter

    def initialize(config)
      @docker_image_name = config.fetch("image_name", nil)
      @docker_registry   = config.fetch("registry")
      @docker_image_tag  = config.fetch("tag", nil)
      @image_builder     = config.fetch("image_builder", "docker")
      @earthly_version   = config.fetch("earthly_version", "0.6")
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
        earthly_version:   earthly_version,
        commit_linter:     commit_linter,
        docker_linter:     docker_linter,
        matrix:            matrix.map(&:to_h),
      }
    end

  end
end
