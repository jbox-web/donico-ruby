# frozen_string_literal: true

module Donico
  module Tasks
    class Docker < Base

      def build
        cmd = ["docker", "build", "-f", image.dockerfile, "--pull", "--tag", image.build_tag, *image.build_args, "."]
        Donico.exec(*cmd)
      end


      def test
        cmd = ["bin/inspec", "donico", image.build_tag, *image.test_args]
        Donico.exec(*cmd)
      end


      def tag
        result = []
        image.tags.each do |tag|
          cmd = ["docker", "tag", image.build_tag, image.prod_tag(tag)]
          result << Donico.run_cmd(*cmd)
        end
        exit_code = result.include?(false) ? 1 : 0
        Kernel.exit(exit_code)
      end


      def push
        result = []
        image.tags.each do |tag|
          cmd = ["docker", "push", image.prod_tag(tag)]
          result << Donico.run_cmd(*cmd)
        end
        exit_code = result.include?(false) ? 1 : 0
        Kernel.exit(exit_code)
      end


      def clean
        cmd = ["docker", "rmi", image.build_tag]
        Donico.exec(*cmd)
      end


      def login
        cmd = ["docker", "run", "-it", "--rm", image.build_tag, "/bin/bash"]
        Donico.exec(*cmd)
      end

    end
  end
end
