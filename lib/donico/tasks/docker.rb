# frozen_string_literal: true

module Donico
  module Tasks
    class Docker < Base

      def build
        cmd = ["docker", "build", "-f", "Dockerfile", "--pull", "--tag", image.build_tag, *image.build_args, "."]
        Donico.exec(*cmd)
      end


      def test
        cmd = ["bin/inspec", "donico", image.build_tag, *image.test_args]
        Donico.exec(*cmd)
      end


      def tag
        cmd = ["docker", "tag", image.build_tag, image.prod_tag]
        Donico.exec(*cmd)
      end


      def push
        cmd = ["docker", "push", image.prod_tag]
        Donico.exec(*cmd)
      end


      def login
        cmd = ["docker", "run", "-it", "--rm", image.build_tag, "/bin/bash"]
        Donico.exec(*cmd)
      end

    end
  end
end
