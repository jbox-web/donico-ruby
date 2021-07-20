# frozen_string_literal: true

module Donico
  module Images
    class Docker < Base
      def build_tag
        format("%<arch>s/%<distro>s/%<name>s-%<version>s:%<tag>s", arch: arch, distro: distro, name: name, version: version, tag: timestamp)
      end

      def prod_tag(tag)
        new_tag = format(tag, version: version, distro: distro)
        image_name = format("%<name>s:%<tag>s", name: name, tag: new_tag)
        "#{registry}/#{image_name}"
      end

      def build_args
        args = (@build_args + ["ARCH=#{arch}", "DISTRO_NAME=#{distro}", "#{version_env_var}=#{version}"]).sort
        args.map { |_| "--build-arg" }.zip(args).flatten
      end

      def test_args
        ["#{version_env_var.downcase}=#{version}"]
      end
    end
  end
end
