# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Config do
  let(:config)  { YAML.load_file(get_fixture_path("donico.yml")) }
  let(:subject) { described_class.new(config) }

  describe "#docker_image_name" do
    context "when value is set" do
      it "returns Donico docker_image_name" do
        expect(subject.docker_image_name).to eq "foo"
      end
    end

    context "when value is not set" do
      let(:config) { super().reject { |k, _v| k == "image_name" } }
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
      let(:config) { super().reject { |k, _v| k == "registry" } }
      it "raises an error" do
        expect do
          subject.docker_registry
        end.to raise_error(KeyError)
      end
    end
  end

  describe "#docker_image_tag" do
    context "when value is set" do
      it "returns Donico docker_image_tag" do
        expect(subject.docker_image_tag).to eq "latest"
      end
    end

    context "when value is not set" do
      let(:config) { super().reject { |k, _v| k == "tag" } }
      it "returns a default value" do
        expect(subject.docker_image_tag).to eq nil
      end
    end
  end

  describe "#image_builder" do
    context "when value is set" do
      it "returns Donico image_builder" do
        expect(subject.image_builder).to eq "donico"
      end
    end

    context "when value is not set" do
      let(:config) { super().reject { |k, _v| k == "image_builder" } }
      it "returns a default value" do
        expect(subject.image_builder).to eq "donico"
      end
    end
  end

  describe "#matrix" do
    context "when value is set" do
      it "returns Donico matrix" do
        expect(subject.matrix).to eq [{ "archs" => ["amd64"], "distro" => "buster", "version" => "1.0.0" }]
      end
    end

    context "when value is not set" do
      let(:config) { super().reject { |k, _v| k == "matrix" } }
      it "returns a default value" do
        expect(subject.matrix).to eq []
      end
    end
  end

  describe "#commit_linter" do
    context "when value is set" do
      it "returns Donico commit_linter" do
        expect(subject.commit_linter).to eq "registry.digitick.net/images/base/amd64/buster/commitlint:latest"
      end
    end

    context "when value is not set" do
      let(:config) { super().reject { |k, _v| k == "commit_linter" } }
      it "returns a default value" do
        expect(subject.commit_linter).to eq "registry.digitick.net/images/base/amd64/buster/commitlint:latest"
      end
    end
  end

  describe "#docker_linter" do
    context "when value is set" do
      it "returns Donico docker_linter" do
        expect(subject.docker_linter).to eq "registry.digitick.net/images/base/amd64/buster/hadolint:latest"
      end
    end

    context "when value is not set" do
      let(:config) { super().reject { |k, _v| k == "docker_linter" } }
      it "returns a default value" do
        expect(subject.docker_linter).to eq "registry.digitick.net/images/base/amd64/buster/hadolint:latest"
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
