# frozen_string_literal: true

module Donico
  class Matrix
    class << self
      def generate(config:)
        matrix = config.matrix.map { |m| m.matrix_for(config.image_builder) }
        write_matrix(matrix)
      end

      # rubocop:disable Metrics/MethodLength
      def write_matrix(matrix)
        warning = "# !!! THIS IS A GENERATED FILE !!! DON'T EDIT ME MANUALLY !!!\n# Instead edit donico.yml and run bin/rake generate-matrix\n"
        config  = {
          ".matrix" => {
            "parallel" => {
              "matrix" => matrix,
            },
          },
        }

        FileUtils.mkdir_p(".gitlab-ci/extends")
        File.open(".gitlab-ci/extends/.matrix.yml", "w") do |f|
          f.write warning
          f.write YAML.dump(config)
        end
      end
      # rubocop:enable Metrics/MethodLength
    end

    attr_reader :image_name, :version, :distro, :archs, :dockerfile, :build_args, :test_args, :secret_envs, :secret_files, :tags

    def initialize(opts = {})
      @image_name   = opts.fetch("image_name", nil)
      @version      = opts.fetch("version", "latest").to_s
      @distro       = opts.fetch("distro", "buster")
      @archs        = opts.fetch("archs", ["linux/amd64"])
      @dockerfile   = opts.fetch("dockerfile", "Dockerfile")
      @build_args   = opts.fetch("build_args", [])
      @test_args    = opts.fetch("test_args", [])
      @secret_envs  = opts.fetch("secret_envs", [])
      @secret_files = opts.fetch("secret_files", [])
      @tags         = opts.fetch("tags", ["%<version>s-%<distro>s"])
    end

    def matrix_for(image_builder)
      case image_builder
      when "docker"
        { "VERSION" => version, "DOCKER_DISTRO" => distro, "DOCKER_ARCH" => archs }
      when "bake"
        { "VERSION" => version, "DOCKER_DISTRO" => distro }
      else
        raise "Unknown image_builder: #{image_builder}"
      end
    end

    def to_h # rubocop:disable Metrics/MethodLength
      {
        archs:        archs,
        distro:       distro,
        version:      version,
        dockerfile:   dockerfile,
        build_args:   build_args,
        test_args:    test_args,
        secret_envs:  secret_envs,
        secret_files: secret_files,
        tags:         tags,
      }
    end
  end
end
