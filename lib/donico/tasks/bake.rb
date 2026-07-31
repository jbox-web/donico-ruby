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

    end
  end
end
