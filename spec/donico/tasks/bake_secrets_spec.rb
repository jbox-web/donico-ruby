# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

# buildx resolves a declared secret against the environment, and silently falls
# back to reading a FILE named after the id when the variable is not set. The
# resulting "failed to stat GITHUB_TOKEN: no such file or directory" names a file
# nobody ever mentioned, so the real cause -- an unexported variable -- is
# invisible. Donico knows the declared secrets, so it can say it plainly.
RSpec.describe Donico::Tasks::Bake do
  def image_with(secrets)
    Donico::Config.new(
      "registry"      => "registry.example.net",
      "image_name"    => "foo",
      "image_builder" => "bake",
      "matrix"        => [{ "version" => "1.0.0" }.merge(secrets)]
    ).then { |config| Donico.instance_variable_set(:@config, config) }

    Donico::Images::Base.build_image_from_matrix(matrix: Donico.config.matrix.first)
  end

  around do |example|
    previous = ENV.fetch("GITHUB_TOKEN", nil)
    example.run
    previous.nil? ? ENV.delete("GITHUB_TOKEN") : ENV["GITHUB_TOKEN"] = previous
  end

  describe "#build" do
    let(:image) { image_with("secret_envs" => [{ "id" => "GITHUB_TOKEN" }]) }

    context "when a declared secret env is missing" do
      it "names the variable instead of letting buildx report a missing file" do
        ENV.delete("GITHUB_TOKEN")

        expect { described_class.build(image) }
          .to raise_error(Donico::EnvironmentError, /GITHUB_TOKEN.*secret_envs/m)
      end

      it "does not spawn docker" do
        ENV.delete("GITHUB_TOKEN")
        expect(Kernel).not_to receive(:exec)

        expect { described_class.build(image) }.to raise_error(Donico::EnvironmentError)
      end
    end

    context "when the variable is set" do
      it "runs the build" do
        ENV["GITHUB_TOKEN"] = "s3cr3t"
        expect(Kernel).to receive(:exec)

        described_class.build(image)
      end
    end

    context "when no secret is declared" do
      let(:image) { image_with({}) }

      it "runs the build" do
        expect(Kernel).to receive(:exec)

        described_class.build(image)
      end
    end
  end

  describe "#push" do
    let(:image) { image_with("secret_envs" => [{ "id" => "GITHUB_TOKEN" }]) }

    it "applies the same check" do
      ENV.delete("GITHUB_TOKEN")

      expect { described_class.push(image) }.to raise_error(Donico::EnvironmentError, /GITHUB_TOKEN/)
    end
  end

  describe "secret files" do
    it "reports a source that does not exist" do
      image = image_with("secret_files" => [{ "id" => "aws", "src" => "/nope/credentials" }])

      expect { described_class.build(image) }.to raise_error(Donico::EnvironmentError, %r{/nope/credentials})
    end

    it "accepts an existing source" do
      Dir.mktmpdir do |dir|
        src = File.join(dir, "credentials")
        File.write(src, "x")
        image = image_with("secret_files" => [{ "id" => "aws", "src" => src }])
        expect(Kernel).to receive(:exec)

        described_class.build(image)
      end
    end

    # "${HOME}/.aws/credentials" is an HCL reference resolved by bake itself, so
    # Donico cannot stat it and must not pretend the path is missing.
    it "leaves a source holding an HCL reference alone" do
      image = image_with("secret_files" => [{ "id" => "aws", "src" => "${HOME}/.aws/credentials" }])
      expect(Kernel).to receive(:exec)

      described_class.build(image)
    end
  end
end
