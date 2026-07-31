# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Images::Docker do
  before { Donico.load_config(get_fixture_path("docker/custom.yml")) }

  let(:timestamp) { Time.now.strftime("%Y%m%d") }
  let(:image) { described_class.build_image_from_matrix(matrix: Donico.config.matrix.first, arch: "linux/amd64") }

  describe "#build_tag" do
    it "builds the local tag from the arch, distro, name and version" do
      expect(image.build_tag).to eq "amd64/buster/foo-1.0.0:#{timestamp}"
    end
  end

  describe "#prod_tag" do
    it "expands the tag macros against the registry" do
      expect(image.prod_tag("%<version>s-%<distro>s-%<arch>s")).to eq "registry.example.net/images/base/foo:1.0.0-buster-amd64"
    end
  end

  describe "#build_args" do
    it "returns the sorted docker CLI form" do
      expect(image.build_args).to eq [
        "--build-arg", "ARCH=amd64",
        "--build-arg", "BUILD_DATE=#{timestamp}",
        "--build-arg", "DISTRO_NAME=buster",
        "--build-arg", "FOO_VERSION=1.0.0",
        "--build-arg", "NODEJS_VERSION=14.17.3",
      ]
    end
  end

  describe "#test_args" do
    it "downcases the input names" do
      expect(image.test_args).to include("distro_name=buster", "nodejs_version=14.17.3")
    end

    # Inspec input names are lowercase, their values are not: downcasing the whole
    # "KEY=VALUE" pair corrupts anything case sensitive (base64, tokens, paths).
    context "when a build arg holds a case sensitive value" do
      let(:matrix) { Donico::Matrix.new("version" => "1.0.0", "build_args" => ["BAR_VERSION=Zm9vCg=="]) }
      let(:image) { described_class.build_image_from_matrix(matrix: matrix, arch: "linux/amd64") }

      it "preserves the value verbatim" do
        expect(image.test_args).to include("bar_version=Zm9vCg==")
      end
    end
  end
end
