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


      def build_args_hash
        raw_build_args.to_h { |arg| arg.split("=", 2) }
      end


      def test_args
        to_inspec_inputs((@build_args + @test_args + base_args).sort)
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
