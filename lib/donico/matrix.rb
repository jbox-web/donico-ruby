# frozen_string_literal: true

module Donico
  class Matrix
    class << self
      def generate(matrix)
        global_matrix = []

        matrix.each do |m|
          version       = m["version"].to_s
          distro_name   = m["distro"]
          architectures = m["archs"]

          global_matrix << { "VERSION" => version, "DOCKER_DISTRO" => distro_name, "DOCKER_ARCH" => architectures }
        end

        write_matrix(global_matrix)
      end

      # rubocop:disable Metrics/MethodLength
      def write_matrix(matrix)
        warning = "# !!! THIS IS A GENERATED FILE !!! DON'T EDIT ME MANUALLY !!!\n# Instead edit donico.yml and run bin/rake generate-matrix\n"
        config  = {
          ".matrix" => {
            "parallel" => {
              "matrix" => matrix
            }
          }
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
  end
end
