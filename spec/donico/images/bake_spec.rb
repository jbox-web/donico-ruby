# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Images::Bake do
  before { Donico.load_config(get_fixture_path("bake/custom.yml")) }

  let(:timestamp) { Time.now.strftime("%Y%m%d") }
  let(:image) { described_class.build_image_from_matrix(matrix: Donico.config.matrix.first) }

  describe "#build_tag" do
    it "builds the local tag from the name, version and distro" do
      expect(image.build_tag).to eq "foo-bar/1.0.0/buster:#{timestamp}"
    end
  end

  describe "#prod_tags" do
    it "expands and sorts every configured tag" do
      expect(image.prod_tags).to eq [
        "registry.example.net/images/base/foo-bar:1.0.0",
        "registry.example.net/images/base/foo-bar:1.0.0-buster",
        "registry.example.net/images/base/foo-bar:latest",
      ]
    end
  end

  describe "#raw_build_args" do
    it "returns the raw sorted KEY=VALUE list" do
      expect(image.raw_build_args).to eq [
        "BAR_VERSION=Zm9vCg==",
        "BUILD_DATE=#{timestamp}",
        "DISTRO_NAME=buster",
        "FOO_BAR_VERSION=1.0.0",
        "NODEJS_VERSION=14.17.3",
      ]
    end
  end

  describe "#build_args_hash" do
    it "indexes the build args by name, splitting on the first separator only" do
      expect(image.build_args_hash).to include("BAR_VERSION" => "Zm9vCg==", "DISTRO_NAME" => "buster")
    end
  end

  describe "#cli_build_args" do
    it "returns the docker CLI form" do
      expect(image.cli_build_args.first(2)).to eq ["--build-arg", "BAR_VERSION=Zm9vCg=="]
    end
  end

  describe "#build_task and #push_task" do
    it "names the bake targets after the distro and the dotless version" do
      expect(image.build_task).to eq "buster-1-0-0-build"
      expect(image.push_task).to eq "buster-1-0-0-push"
    end
  end

  describe "#secrets?" do
    it "is true when secret envs or files are declared" do
      expect(image.secrets?).to be true
    end
  end
end
