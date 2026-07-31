# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Images::Base do
  before { Donico.load_config(get_fixture_path("docker/minimal.yml")) }

  def image_named(name)
    matrix = Donico::Matrix.new("image_name" => name, "version" => "1.0.0")
    Donico::Images::Docker.new(**described_class.build_options_for(matrix, "docker", "linux/amd64"), name: name)
  end

  describe "#version_env_var" do
    it "upcases a simple name" do
      expect(image_named("foo").version_env_var).to eq "FOO_VERSION"
    end

    it "turns dashes into underscores" do
      expect(image_named("docker-in-docker").version_env_var).to eq "DOCKER_IN_DOCKER_VERSION"
    end

    # "\1_\2" in a double quoted string is not a backreference: it inserts the
    # 0x01/0x02 control bytes, producing an env var name docker silently ignores.
    it "splits camel case names on the case boundary" do
      expect(image_named("MyApp").version_env_var).to eq "MY_APP_VERSION"
    end

    it "splits consecutive capitals before a capitalised word" do
      expect(image_named("HTTPServer").version_env_var).to eq "HTTP_SERVER_VERSION"
    end
  end

  describe ".build_options_for" do
    # docker/minimal.yml declares a top-level image_name, which used to override the
    # more specific per-matrix one because it was merged last.
    it "prefers the per-matrix image_name over the top-level one" do
      matrix = Donico::Matrix.new("image_name" => "bookworm", "version" => "1.0.0")

      expect(described_class.build_options_for(matrix, "docker", "linux/amd64")[:name]).to eq "bookworm"
    end

    it "falls back to the top-level image_name when the matrix has none" do
      matrix = Donico::Matrix.new("version" => "1.0.0")

      expect(described_class.build_options_for(matrix, "docker", "linux/amd64")[:name]).to eq "foo"
    end

    it "swaps archs for a single arch on the docker backend" do
      opts = described_class.build_options_for(Donico::Matrix.new, "docker", "linux/amd64")

      expect(opts).to include(arch: "linux/amd64")
      expect(opts).not_to have_key(:archs)
    end

    it "keeps the arch list on the bake backend" do
      opts = described_class.build_options_for(Donico::Matrix.new, "bake")

      expect(opts).to include(archs: ["linux/amd64"])
    end
  end

  describe "#secrets?" do
    it "is false when no secret is declared" do
      expect(image_named("foo").secrets?).to be false
    end
  end
end
