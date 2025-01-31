# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Config do
  let(:config_file) { YAML.load_file(get_fixture_path("docker/custom.yml")) }
  let(:config) { described_class.new(config_file) }

  describe "#docker_image_name" do
    context "when value is set" do
      it "returns Donico docker_image_name" do
        expect(config.docker_image_name).to eq "foo"
      end
    end

    # context "when value is not set" do
    #   let(:config_file) { super().except("image_name") }
    #   it "raises an error" do
    #     expect do
    #       config.docker_image_name
    #     end.to raise_error(KeyError)
    #   end
    # end
  end

  describe "#docker_registry" do
    context "when value is set" do
      it "returns Donico docker_registry" do
        expect(config.docker_registry).to eq "registry.example.net/images/base"
      end
    end

    context "when value is not set" do
      let(:config_file) { super().except("registry") }

      it "raises an error" do
        expect do
          config.docker_registry
        end.to raise_error(KeyError)
      end
    end
  end

  describe "#image_builder" do
    context "when value is set" do
      it "returns Donico image_builder" do
        expect(config.image_builder).to eq "docker"
      end
    end

    context "when value is not set" do
      let(:config_file) { super().except("image_builder") }

      it "returns a default value" do
        expect(config.image_builder).to eq "docker"
      end
    end
  end

  describe "#matrix" do
    context "when value is set" do
      let(:matrix) do
        [
          {
            archs:      ["linux/amd64"],
            distro:     "buster",
            version:    "1.0.0",
            dockerfile: "foo/Dockerfile",
            build_args: ["NODEJS_VERSION=14.17.3"],
            test_args:  ["RUBYGEM_VERSION=3.2.24"],
            tags:       [
              "latest",
              "%<version>s",
              "%<version>s-%<distro>s",
              "%<timestamp>s-%<distro>s",
              "%<version>s-%<timestamp>s-%<distro>s",
              "%<version>s-%<timestamp>s-%<distro>s-%<arch>s",
            ],
          },
        ]
      end

      it "returns Donico matrix" do
        expect(config.matrix.map(&:to_h)).to eq matrix
      end
    end

    context "when value is not set" do
      let(:config_file) { super().except("matrix") }

      it "returns a default value" do
        expect(config.matrix.first).to be_a(Donico::Matrix)

        matrix = config.matrix.first
        expect(matrix.version).to eq "latest"
        expect(matrix.distro).to eq "buster"
        expect(matrix.archs).to eq ["linux/amd64"]
        expect(matrix.build_args).to eq []
        expect(matrix.test_args).to eq []
        expect(matrix.tags).to eq ["%<version>s-%<distro>s"]
      end
    end
  end

  describe "#commit_linter" do
    context "when value is set" do
      it "returns Donico commit_linter" do
        expect(config.commit_linter).to eq Donico::DEFAULT_COMMIT_LINTER
      end
    end

    context "when value is not set" do
      let(:config_file) { super().except("commit_linter") }

      it "returns a default value" do
        expect(config.commit_linter).to eq Donico::DEFAULT_COMMIT_LINTER
      end
    end
  end

  describe "#docker_linter" do
    context "when value is set" do
      it "returns Donico docker_linter" do
        expect(config.docker_linter).to eq Donico::DEFAULT_DOCKER_LINTER
      end
    end

    context "when value is not set" do
      let(:config_file) { super().except("docker_linter") }

      it "returns a default value" do
        expect(config.docker_linter).to eq Donico::DEFAULT_DOCKER_LINTER
      end
    end
  end

  describe "#timestamp" do
    context "when CI_COMMIT_TIMESTAMP is not set" do
      before { ENV.delete("CI_COMMIT_TIMESTAMP") }

      it "returns a timestamp to name the image" do
        expect(config.timestamp).to eq Time.now.strftime("%Y%m%d")
      end
    end

    context "when CI_COMMIT_TIMESTAMP is set" do
      before { ENV["CI_COMMIT_TIMESTAMP"] = "2021-06-09T11:50:22Z" }
      after  { ENV.delete("CI_COMMIT_TIMESTAMP") }

      it "returns a timestamp to name the image" do
        expect(config.timestamp).to eq "20210609115022"
      end
    end
  end
end
