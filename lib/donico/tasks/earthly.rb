# frozen_string_literal: true

module Donico
  module Tasks
    class Earthly < Base

      def build
        cmd = ["earthly", *image.formatted_build_args, image.build_task]
        Donico.exec(*cmd)
      end


      def test
        cmd = ["bin/inspec", "donico", image.build_tag, *image.test_args]
        Donico.exec(*cmd)
      end


      def push
        cmd = ["earthly", "--push", *image.formatted_build_args, image.push_task]
        Donico.exec(*cmd)
      end


      def clean
        results = []
        logs    = []

        # Delete main image
        cmd = ["docker", "rmi", image.build_tag]
        result, log = Donico.run_cmd(*cmd)
        results << result
        logs << log

        # Delete arch specific image
        image.archs.each do |arch|
          arch = arch.sub("/", "_")
          cmd = ["docker", "rmi", "#{image.build_tag}_#{arch}"]
          result, log = Donico.run_cmd(*cmd)
          results << result
          logs << log
        end

        # Exit properly
        exit_code = results.include?(false) ? 1 : 0
        Kernel.exit(exit_code)
      end


      def login
        cmd = ["docker", "run", "-it", "--rm", image.build_tag, "/bin/bash"]
        Donico.exec(*cmd)
      end

    end
  end
end
