# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Donico::Matrix do
  describe ".generate" do
    let(:generated) do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          described_class.generate(config: Donico.load_config(get_fixture_path(fixture_file)))
          File.read(".gitlab-ci/extends/.matrix.yml")
        end
      end
    end

    context "with the docker backend" do
      let(:fixture_file) { "docker/multiple_dockerfiles.yml" }

      it "writes one parallel matrix entry per image, arch included" do
        expect(YAML.safe_load(generated)).to eq(
          ".matrix" => {
            "parallel" => {
              "matrix" => [
                { "VERSION" => "3.1.3", "DOCKER_DISTRO" => "bullseye", "DOCKER_ARCH" => ["amd64"] },
                { "VERSION" => "3.2.0", "DOCKER_DISTRO" => "bullseye", "DOCKER_ARCH" => ["amd64"] },
              ],
            },
          }
        )
      end

      # The header used to point at `bin/rake generate-matrix`, a task that does
      # not exist: the only task is generate-files.
      it "points the reader at the task that actually regenerates it" do
        expect(generated).to include("bin/rake generate-files")
        expect(generated).not_to include("generate-matrix")
      end
    end

    context "with the bake backend" do
      let(:fixture_file) { "bake/multiple_dockerfiles.yml" }

      it "omits the arch dimension, which bake handles itself" do
        entries = YAML.safe_load(generated).dig(".matrix", "parallel", "matrix")

        expect(entries).to eq(
          [
            { "VERSION" => "3.2.0", "DOCKER_DISTRO" => "bullseye" },
            { "VERSION" => "3.1.3", "DOCKER_DISTRO" => "buster" },
          ]
        )
      end
    end
  end

  describe "#matrix_for" do
    let(:matrix) { described_class.new("version" => "1.0.0", "distro" => "buster", "archs" => ["linux/amd64"]) }

    it "carries the arch dimension for the docker backend" do
      expect(matrix.matrix_for("docker")).to eq(
        "VERSION" => "1.0.0", "DOCKER_DISTRO" => "buster", "DOCKER_ARCH" => ["linux/amd64"]
      )
    end

    it "drops the arch dimension for the bake backend" do
      expect(matrix.matrix_for("bake")).to eq("VERSION" => "1.0.0", "DOCKER_DISTRO" => "buster")
    end

    # Config rejects an unsupported backend at load time, so this is a guard for a
    # future backend added to Config but not here.
    it "refuses an unsupported backend" do
      expect { matrix.matrix_for("kaniko") }.to raise_error(RuntimeError, /kaniko/)
    end
  end

  describe "#version" do
    context "when version is a quoted string" do
      it "keeps the version untouched" do
        expect(described_class.new("version" => "3.10").version).to eq "3.10"
      end
    end

    context "when version is not set" do
      it "returns the default version" do
        expect(described_class.new.version).to eq "latest"
      end
    end

    # YAML coerces an unquoted `3.10` into the Float 3.1, which silently drops
    # the trailing zero and would publish an image under the wrong version.
    context "when version was coerced into a Float by YAML" do
      it "raises an explicit error asking to quote the version" do
        expect do
          described_class.new("version" => 3.10)
        end.to raise_error(Donico::ConfigError, /version.*must be quoted/i)
      end
    end

    context "when version was coerced into an Integer by YAML" do
      it "raises an explicit error asking to quote the version" do
        expect do
          described_class.new("version" => 3)
        end.to raise_error(Donico::ConfigError, /version.*must be quoted/i)
      end
    end
  end
end
