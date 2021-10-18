# frozen_string_literal: true

module Donico
  class Matrix
    class << self
      def generate(matrix)
        global_matrix = []

        matrix.each do |m|
          global_matrix << { "VERSION" => m.version, "DOCKER_DISTRO" => m.distro, "DOCKER_ARCH" => m.archs }
        end

        write_matrix(global_matrix)
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

        puts "GitlabCI Matrix file generated"
      end
      # rubocop:enable Metrics/MethodLength
    end

    attr_reader :version, :distro, :archs, :build_args, :test_args, :tags

    def initialize(opts = {})
      @version    = opts.fetch("version", "latest").to_s
      @distro     = opts.fetch("distro", "buster")
      @archs      = opts.fetch("archs", ["amd64"])
      @build_args = opts.fetch("build_args", [])
      @test_args  = opts.fetch("test_args", [])
      @tags       = opts.fetch("tags", ["%<version>s-%<distro>s"])
    end

    def to_h
      {
        archs:      archs,
        distro:     distro,
        version:    version,
        build_args: build_args,
        test_args:  test_args,
        tags:       tags,
      }
    end
  end
end
