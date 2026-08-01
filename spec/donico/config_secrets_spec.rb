# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Config do
  def config_for(overrides)
    described_class.new({ "registry" => "registry.example.net", "image_name" => "foo" }.merge(overrides))
  end

  describe "validation" do
    # An id-less secret used to render as `id = ""`: syntactically valid HCL that
    # silently never mounts anything.
    it "rejects a secret env without an id" do
      expect do
        config_for("image_builder" => "bake", "matrix" => [{ "secret_envs" => [{ "src" => "x" }] }])
      end.to raise_error(Donico::ConfigError, /secret_envs.*id/m)
    end

    it "rejects a secret file without an id" do
      expect do
        config_for("image_builder" => "bake", "matrix" => [{ "secret_files" => [{ "src" => "x" }] }])
      end.to raise_error(Donico::ConfigError, /secret_files.*id/m)
    end

    it "rejects a secret file without a src" do
      expect do
        config_for("image_builder" => "bake", "matrix" => [{ "secret_files" => [{ "id" => "aws" }] }])
      end.to raise_error(Donico::ConfigError, /secret_files.*src/m)
    end

    it "names both keys when a secret file declares neither" do
      expect do
        config_for("image_builder" => "bake", "matrix" => [{ "secret_files" => [{}] }])
      end.to raise_error(Donico::ConfigError, /keys: id, src/)
    end

    it "accepts a fully declared secret" do
      expect do
        config_for("image_builder" => "bake",
                   "matrix"        => [{
                     "secret_envs"  => [{ "id" => "GITHUB_TOKEN" }],
                     "secret_files" => [{ "id" => "aws", "src" => "/tmp/creds" }],
                   }])
      end.not_to raise_error
    end
  end

  describe "backend support" do
    # Only the bake template consumes secrets; the docker backend dropped them
    # without a word, so the build ran without the secret it was written for.
    it "warns when secrets are declared with the docker backend" do
      expect do
        config_for("image_builder" => "docker", "matrix" => [{ "secret_envs" => [{ "id" => "GITHUB_TOKEN" }] }])
      end.to output(/secret.*docker backend/im).to_stderr
    end

    it "stays quiet with the bake backend" do
      expect do
        config_for("image_builder" => "bake", "matrix" => [{ "secret_envs" => [{ "id" => "GITHUB_TOKEN" }] }])
      end.not_to output.to_stderr
    end
  end
end
