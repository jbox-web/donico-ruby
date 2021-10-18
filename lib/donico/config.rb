# frozen_string_literal: true

module Donico
  class Config
    attr_reader :docker_image_name, :docker_registry, :docker_image_tag, :image_builder, :matrix, :commit_linter, :docker_linter

    def initialize(config)
      @docker_image_name = config.fetch("image_name")
      @docker_registry   = config.fetch("registry")
      @docker_image_tag  = config.fetch("tag", nil)
      @image_builder     = config.fetch("image_builder", "donico")
      @matrix            = config.fetch("matrix", [{}]).map { |m| Matrix.new(m) }

      @commit_linter     = config.fetch("commit_linter", "harbor.jbox-cloud.fr/jbox/base/commitlint:latest")
      @docker_linter     = config.fetch("docker_linter", "harbor.jbox-cloud.fr/jbox/base/hadolint:latest")
    end

    # When running in CI, use CI_COMMIT_TIMESTAMP as a timestamp to name the build image.
    # When running in dev, generate a timestamp from the current date to name the build image.
    def timestamp
      if ENV.key?("CI_COMMIT_TIMESTAMP")
        date = Time.parse(ENV["CI_COMMIT_TIMESTAMP"])
        date.strftime("%Y%m%d%H%M%S")
      else
        date = Time.now
        date.strftime("%Y%m%d")
      end
    end

  end
end
