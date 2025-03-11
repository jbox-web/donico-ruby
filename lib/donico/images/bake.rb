# frozen_string_literal: true

module Donico
  module Images
    class Bake < Base

      attr_reader :archs


      def initialize(archs:, **opts)
        @archs = archs
        super(**opts)
      end


      def build_tag
        format_tag("%<name>s/%<version>s/%<distro>s:%<tag>s", distro: distro, name: name, version: version, tag: timestamp)
      end


      def prod_tags
        tags.map { |t| prod_tag(t) }.sort
      end


      def build_args
        (@build_args + ["DISTRO_NAME=#{distro}", "BUILD_DATE=#{timestamp}", "#{version_env_var}=#{version}"]).sort
      end


      def build_args_hash
        data = {}
        build_args.each do |arg|
          name, value = arg.split("=", 2)
          data[name] = value
        end
        data
      end


      def formatted_build_args
        build_args.map { |_| "--build-arg" }.zip(build_args).flatten
      end


      def test_args
        (@build_args + @test_args + ["DISTRO_NAME=#{distro}", "BUILD_DATE=#{timestamp}", "#{version_env_var}=#{version}"]).sort.map(&:downcase)
      end


      def build_task
        "#{distro}-#{version.tr('.', '-')}-build"
      end


      def push_task
        "#{distro}-#{version.tr('.', '-')}-push"
      end


      private


      def prod_tag(tag)
        new_tag = format_tag(tag, version: version, distro: distro, timestamp: timestamp)
        image_name = format_tag("%<name>s:%<tag>s", name: name, tag: new_tag)
        "#{registry}/#{image_name}"
      end

    end
  end
end
