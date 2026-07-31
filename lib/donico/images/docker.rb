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
        format_tag("%<arch>s/%<distro>s/%<name>s-%<version>s:%<tag>s", arch: deprecated_arch, distro: distro, name: name, version: version, tag: timestamp)
      end


      def prod_tag(tag)
        new_tag = format_tag(tag, version: version, distro: distro, timestamp: timestamp, arch: deprecated_arch)
        image_name = format_tag("%<name>s:%<tag>s", name: name, tag: new_tag)
        "#{registry}/#{image_name}"
      end


      def build_args
        args = (@build_args + base_args).sort
        args.map { |_| "--build-arg" }.zip(args).flatten
      end


      def test_args
        to_inspec_inputs((@build_args + @test_args + base_args).sort)
      end


      private


      def base_args
        super.prepend("ARCH=#{deprecated_arch}")
      end

    end
  end
end
