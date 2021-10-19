# frozen_string_literal: true

module Donico
  module Images
    class Docker < Base

      attr_reader :arch, :deprecated_arch


      def initialize(arch:, **opts)
        @arch = arch
        @deprecated_arch = arch.split("/").last
        super(**opts)
      end


      def build_tag
        format("%<arch>s/%<distro>s/%<name>s-%<version>s:%<tag>s", arch: deprecated_arch, distro: distro, name: name, version: version, tag: timestamp)
      end


      def prod_tag(tag)
        new_tag = format(tag, version: version, distro: distro, timestamp: timestamp, arch: deprecated_arch)
        image_name = format("%<name>s:%<tag>s", name: name, tag: new_tag)
        "#{registry}/#{image_name}"
      end


      def build_args
        args = (@build_args + ["ARCH=#{deprecated_arch}", "DISTRO_NAME=#{distro}", "#{version_env_var}=#{version}"]).sort
        args.map { |_| "--build-arg" }.zip(args).flatten
      end


      def test_args
        (@build_args + @test_args + ["ARCH=#{deprecated_arch}", "DISTRO_NAME=#{distro}", "#{version_env_var}=#{version}"]).sort.map(&:downcase)
      end

    end
  end
end
