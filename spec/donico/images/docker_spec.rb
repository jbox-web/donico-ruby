# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Images::Docker do
  # A fixed CI_COMMIT_TIMESTAMP pins the expected tags: reading the clock instead
  # made the expectation depend on the format Config picks, so these examples
  # passed or failed according to whether the suite ran in CI. spec_helper
  # restores the variable afterwards.
  before do
    ENV["CI_COMMIT_TIMESTAMP"] = "2026-07-31T20:59:35Z"
    Donico.load_config(get_fixture_path("docker/custom.yml"))
  end

  let(:timestamp) { "20260731205935" }
  let(:image) { described_class.build_image_from_matrix(matrix: Donico.config.matrix.first, arch: "linux/amd64") }

  describe "#build_tag" do
    it "builds the local tag from the arch, distro, name and version" do
      expect(image.build_tag).to eq "amd64/buster/foo-1.0.0:#{timestamp}"
    end
  end

  # bake sorted its tags while docker kept the donico.yml order, so migrating a
  # repo from one backend to the other reshuffled the logs for no functional reason.
  describe "#prod_tags" do
    it "returns every configured tag, sorted" do
      expect(image.prod_tags).to eq [
        "registry.example.net/images/base/foo:1.0.0",
        "registry.example.net/images/base/foo:1.0.0-#{timestamp}-buster",
        "registry.example.net/images/base/foo:1.0.0-#{timestamp}-buster-amd64",
        "registry.example.net/images/base/foo:1.0.0-buster",
        "registry.example.net/images/base/foo:#{timestamp}-buster",
        "registry.example.net/images/base/foo:latest",
      ]
    end
  end

  describe "#prod_tag" do
    it "expands the tag macros against the registry" do
      expect(image.prod_tag("%<version>s-%<distro>s-%<arch>s")).to eq "registry.example.net/images/base/foo:1.0.0-buster-amd64"
    end
  end

  describe "#cli_build_args" do
    it "returns the sorted docker CLI form" do
      expect(image.cli_build_args).to eq [
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
