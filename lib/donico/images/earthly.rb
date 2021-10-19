# frozen_string_literal: true

module Donico
  module Images
    class Earthly < Base

      attr_reader :archs


      def initialize(archs:, **opts)
        @archs = archs
        super(**opts)
      end


      def build_tag
        format("%<name>s/%<version>s/%<distro>s:%<tag>s", distro: distro, name: name, version: version, tag: timestamp)
      end


      def prod_tags
        tags.map { |t| prod_tag(t) }.sort
      end


      def build_args
        (@build_args + ["DISTRO_NAME=#{distro}", "#{version_env_var}=#{version}", "TIMESTAMP=#{timestamp}"]).sort
      end


      def formatted_build_args
        build_args.map { |_| "--build-arg" }.zip(build_args).flatten
      end


      def test_args
        (@build_args + @test_args + ["DISTRO_NAME=#{distro}", "#{version_env_var}=#{version}"]).sort.map(&:downcase)
      end


      def build_task
        "+#{distro}-#{version}-build-all"
      end


      def push_task
        "+#{distro}-#{version}-push-all"
      end


      private


      def prod_tag(tag)
        new_tag = format(tag, version: version, distro: distro, timestamp: timestamp)
        image_name = format("%<name>s:%<tag>s", name: name, tag: new_tag)
        "#{registry}/#{image_name}"
      end

    end
  end
end
