# frozen_string_literal: true

module Donico
  module Tasks
    class Bake < Base

      class << self

        def generate_bakefile
          Donico::Templates::Bakefile.generate
        end

      end


      def build
        verify_secrets_available!

        cmd = ["docker", "buildx", "bake", image.build_task]
        Donico.exec(*cmd, env: image.build_args_hash)
      end


      def test
        cmd = ["bin/inspec", "donico", image.build_tag, *image.test_args]
        Donico.exec(*cmd)
      end


      # Tasks::Base exposes .tag for every backend, but bake builds and applies its
      # tags itself when pushing (see the push target of docker-bake.hcl), so there
      # is no separate tag step here. Say so instead of raising a bare NoMethodError.
      def tag
        raise NotImplementedError,
              "The bake backend has no separate tag step: tags are applied by the push target of docker-bake.hcl."
      end


      def push
        verify_secrets_available!

        cmd = ["docker", "buildx", "bake", image.push_task]
        Donico.exec(*cmd, env: image.build_args_hash)
      end


      def clean
        results = []
        logs    = []

        # Delete main image
        cmd = ["docker", "rmi", image.build_tag]
        result, log = Donico.run_cmd(*cmd)
        results << result
        logs << log

        # Exit properly
        exit_code = results.include?(false) ? 1 : 0
        puts logs.join("\n") if exit_code == 1
        Kernel.exit(exit_code)
      end


      def login
        cmd = ["docker", "run", "-it", "--rm", image.build_tag, "/bin/bash"]
        Donico.exec(*cmd)
      end


      private


      # buildx resolves a declared secret against the environment and, when the
      # variable is unset, silently falls back to reading a FILE named after the
      # id. It then reports "failed to stat GITHUB_TOKEN: no such file or
      # directory" — a file nobody ever mentioned — which hides the real cause.
      # Donico knows what was declared, so it says it before spawning docker.
      def verify_secrets_available!
        missing = missing_secret_envs + missing_secret_files
        return if missing.empty?

        raise EnvironmentError, "\n#{missing.join("\n")}\n\n"
      end


      def missing_secret_envs
        image.secret_envs
             .reject { |s| ENV.key?(s["id"]) }
             .map { |s| "Secret #{s['id'].inspect} is declared in secret_envs but no such variable is set. Export it before building." }
      end


      # A src holding an HCL reference such as "${HOME}/.aws/credentials" is
      # resolved by bake itself, so Donico cannot stat it and must not claim it
      # is missing.
      def missing_secret_files
        image.secret_files
             .reject { |s| s["src"].to_s.include?("${") || File.exist?(s["src"].to_s) }
             .map { |s| "Secret #{s['id'].inspect} is declared in secret_files but its src #{s['src'].inspect} does not exist." }
      end

    end
  end
end
