# frozen_string_literal: true

module Donico
  module Images
    class Docker < Base
      def build_tag
        format("%<arch>s/%<distro>s/%<name>s-%<version>s:%<tag>s", arch: arch, distro: distro, name: name, version: version, tag: timestamp)
      end

      def prod_tag
        final_tag = tag || version
        image_name = format("%<arch>s/%<distro>s/%<name>s:%<tag>s", arch: arch, distro: distro, name: name, tag: final_tag)
        "#{registry}/#{image_name}"
      end

      def build_args
        ["--build-arg", "ARCH=#{arch}", "--build-arg", "DISTRO_NAME=#{distro}", "--build-arg", "#{version_env_var}=#{version}"]
      end

      def test_args
        ["#{version_env_var.downcase}=#{version}"]
      end
    end
  end
end
