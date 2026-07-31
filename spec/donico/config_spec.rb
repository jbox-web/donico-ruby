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

    # Without a name anywhere, tags used to render with an empty segment
    # ("/1.0.0/buster:20260731") and the version env var became "_VERSION".
    context "when neither the config nor the matrix names the image" do
      let(:config_file) { super().except("image_name") }

      it "raises an explicit error" do
        expect { config }.to raise_error(Donico::ConfigError, /image_name/)
      end
    end

    context "when only the matrix names the image" do
      let(:config_file) do
        super().except("image_name").merge("matrix" => [{ "version" => "1.0.0", "image_name" => "bookworm" }])
      end

      it "is accepted" do
        expect { config }.not_to raise_error
      end
    end
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

    # An unvalidated value used to fail three different ways depending on the code
    # path taken (LoadError, RuntimeError, NameError), and was interpolated into a
    # file path passed to Kernel#load.
    context "when value is not a supported backend" do
      let(:config_file) { super().merge("image_builder" => "kaniko") }

      it "raises an explicit error listing the supported backends" do
        expect { config }.to raise_error(Donico::ConfigError, /kaniko.*docker.*bake/m)
      end
    end
  end

  describe "#matrix" do
    context "when value is set" do
      let(:matrix) do
        [
          {
            archs:        ["linux/amd64"],
            distro:       "buster",
            version:      "1.0.0",
            dockerfile:   "foo/Dockerfile",
            build_args:   ["NODEJS_VERSION=14.17.3"],
            test_args:    ["RUBYGEM_VERSION=3.2.24"],
            secret_envs:  [],
            secret_files: [],
            tags:         [
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

  describe "#dockerfiles" do
    # `dockerfile` defaults to "Dockerfile", so a config with N distros used to run
    # hadolint N times (N image pulls, N containers) on the very same file.
    context "when several matrix entries share the same dockerfile" do
      let(:config_file) do
        super().merge("matrix" => [
                        { "version" => "1.0.0", "distro" => "buster" },
                        { "version" => "2.0.0", "distro" => "bullseye" },
                      ])
      end

      it "returns each dockerfile once" do
        expect(config.dockerfiles).to eq ["/app/Dockerfile"]
      end
    end

    context "when matrix entries use distinct dockerfiles" do
      let(:config_file) do
        super().merge("matrix" => [
                        { "version" => "1.0.0", "dockerfile" => "a/Dockerfile" },
                        { "version" => "2.0.0", "dockerfile" => "b/Dockerfile" },
                      ])
      end

      it "returns them all" do
        expect(config.dockerfiles).to eq ["/app/a/Dockerfile", "/app/b/Dockerfile"]
      end
    end
  end

  describe "#timestamp" do
    context "when CI_COMMIT_TIMESTAMP is not set" do
      it "returns a timestamp to name the image" do
        allow(Time).to receive(:now).and_return(Time.parse("2026-07-31T23:59:59Z"))

        expect(config.timestamp).to eq "20260731"
      end

      # Recomputing Time.now on every call made the build tag change under the feet
      # of a run straddling midnight: build wrote one tag, tag looked for another.
      it "keeps the same timestamp across calls within a process" do
        allow(Time).to receive(:now).and_return(Time.parse("2026-07-31T23:59:59Z"))
        first = config.timestamp
        allow(Time).to receive(:now).and_return(Time.parse("2026-08-01T00:00:01Z"))

        expect(config.timestamp).to eq first
      end
    end

    context "when CI_COMMIT_TIMESTAMP is set" do
      before { ENV["CI_COMMIT_TIMESTAMP"] = "2021-06-09T11:50:22Z" }

      it "returns a timestamp to name the image" do
        expect(config.timestamp).to eq "20210609115022"
      end
    end
  end
end
