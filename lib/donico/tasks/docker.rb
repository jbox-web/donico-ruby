# frozen_string_literal: true

module Donico
  module Tasks
    class Docker < Base

      def build
        cmd = ["docker", "build", "-f", image.dockerfile, "--pull", "--tag", image.build_tag, *image.cli_build_args, "."]
        Donico.exec(*cmd)
      end


      def test
        cmd = ["bin/inspec", "donico", image.build_tag, *image.test_args]
        Donico.exec(*cmd)
      end


      def tag
        run_cmd_with_tags(image.prod_tags) do |prod_tag|
          ["docker", "tag", image.build_tag, prod_tag]
        end
      end


      def push
        run_cmd_with_tags(image.prod_tags) do |prod_tag|
          ["docker", "push", prod_tag]
        end
      end


      def clean
        cmd = ["docker", "rmi", image.build_tag]
        Donico.exec(*cmd)
      end


      def login
        cmd = ["docker", "run", "-it", "--rm", image.build_tag, "/bin/bash"]
        Donico.exec(*cmd)
      end


      private


      def run_cmd_with_tags(tags)
        results = []
        logs    = []

        tags.each do |tag|
          cmd = yield tag
          result, log = Donico.run_cmd(*cmd)
          results << result
          logs << log
        end

        render_logs(logs)
        exit_code(results)
      end


      def render_logs(logs)
        logs = logs.reject(&:empty?)
        puts logs.join("\n") unless logs.empty?
      end


      def exit_code(results)
        exit_code = results.include?(false) ? 1 : 0
        Kernel.exit(exit_code)
      end

    end
  end
end
