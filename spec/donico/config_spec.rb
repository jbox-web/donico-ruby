# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Config do
  let(:config)  { YAML.load_file(get_fixture_path("docker/custom.yml")) }
  let(:subject) { described_class.new(config) }

  describe "#docker_image_name" do
    context "when value is set" do
      it "returns Donico docker_image_name" do
        expect(subject.docker_image_name).to eq "foo"
      end
    end

    context "when value is not set" do
      let(:config) { super().except("image_name") }
      it "raises an error" do
        expect do
          subject.docker_image_name
        end.to raise_error(KeyError)
      end
    end
  end

  describe "#docker_registry" do
    context "when value is set" do
      it "returns Donico docker_registry" do
        expect(subject.docker_registry).to eq "registry.example.net/images/base"
      end
    end

    context "when value is not set" do
      let(:config) { super().except("registry") }
      it "raises an error" do
        expect do
          subject.docker_registry
        end.to raise_error(KeyError)
      end
    end
  end

  describe "#image_builder" do
    context "when value is set" do
      it "returns Donico image_builder" do
        expect(subject.image_builder).to eq "docker"
      end
    end

    context "when value is not set" do
      let(:config) { super().except("image_builder") }
      it "returns a default value" do
        expect(subject.image_builder).to eq "docker"
      end
    end
  end

  describe "#matrix" do
    context "when value is set" do
      it "returns Donico matrix" do
        expect(subject.matrix.map(&:to_h)).to eq [
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
              "%<version>s-%<timestamp>s-%<distro>s-%<arch>s"
            ],
          }
        ]
      end
    end

    context "when value is not set" do
      let(:config) { super().except("matrix") }
      it "returns a default value" do
        expect(subject.matrix.first).to be_a(Donico::Matrix)

        matrix = subject.matrix.first
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
        expect(subject.commit_linter).to eq Donico::DEFAULT_COMMIT_LINTER
      end
    end

    context "when value is not set" do
      let(:config) { super().except("commit_linter") }
      it "returns a default value" do
        expect(subject.commit_linter).to eq Donico::DEFAULT_COMMIT_LINTER
      end
    end
  end

  describe "#docker_linter" do
    context "when value is set" do
      it "returns Donico docker_linter" do
        expect(subject.docker_linter).to eq Donico::DEFAULT_DOCKER_LINTER
      end
    end

    context "when value is not set" do
      let(:config) { super().except("docker_linter") }
      it "returns a default value" do
        expect(subject.docker_linter).to eq Donico::DEFAULT_DOCKER_LINTER
      end
    end
  end

  describe "#timestamp" do
    context "when CI_COMMIT_TIMESTAMP is not set" do
      before { ENV.delete("CI_COMMIT_TIMESTAMP") }

      it "returns a timestamp to name the image" do
        expect(subject.timestamp).to eq Time.now.strftime("%Y%m%d")
      end
    end

    context "when CI_COMMIT_TIMESTAMP is set" do
      before { ENV["CI_COMMIT_TIMESTAMP"] = "2021-06-09T11:50:22Z" }
      after  { ENV.delete("CI_COMMIT_TIMESTAMP") }

      it "returns a timestamp to name the image" do
        expect(subject.timestamp).to eq "20210609115022"
      end
    end
  end
end
