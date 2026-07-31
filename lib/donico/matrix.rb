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
        warning = "# !!! THIS IS A GENERATED FILE !!! DON'T EDIT ME MANUALLY !!!\n# Instead edit donico.yml and run bin/rake generate-files\n"
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
      @version      = validate_version!(opts.fetch("version", "latest"))
      @distro       = opts.fetch("distro", "buster")
      @archs        = opts.fetch("archs", ["linux/amd64"])
      @dockerfile   = opts.fetch("dockerfile", "Dockerfile")
      @build_args   = opts.fetch("build_args", [])
      @test_args    = opts.fetch("test_args", [])
      @secret_envs  = validate_secrets!(opts.fetch("secret_envs", []), "secret_envs", %w[id])
      @secret_files = validate_secrets!(opts.fetch("secret_files", []), "secret_files", %w[id src])
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

    private

    # YAML coerces an unquoted `3.10` into the Float 3.1 and an unquoted `3` into
    # the Integer 3. Calling #to_s on those silently drops the trailing zero, so the
    # image would be built AND tagged with a version the user never wrote.
    # The original text cannot be recovered, so refuse the config instead of guessing.
    def validate_version!(version)
      return version if version.is_a?(String)

      raise ConfigError,
            "\nInvalid version in donico.yml: #{version.inspect} (#{version.class}).\n" \
            "The version must be quoted so YAML keeps it verbatim: version: \"#{version}\"\n\n"
    end

    # A secret missing its id used to render as `id = ""` in the bakefile:
    # syntactically valid HCL that silently mounts nothing.
    def validate_secrets!(secrets, key, required_keys)
      secrets.each do |secret|
        missing = required_keys.reject { |k| secret.is_a?(Hash) && !secret[k].to_s.empty? }
        next if missing.empty?

        raise ConfigError,
              "\nInvalid #{key} entry in donico.yml: #{secret.inspect}.\n" \
              "Missing required #{missing.size > 1 ? 'keys' : 'key'}: #{missing.join(', ')}.\n\n"
      end
    end
  end
end
