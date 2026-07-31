# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico do
  describe ".root_dir" do
    it "returns Donico root dir" do
      expect(described_class.root_dir).to eq File.realpath(File.dirname(File.expand_path("../donico.gemspec", __dir__)))
    end
  end

  describe ".tasks_dir" do
    it "returns Donico tasks dir" do
      expect(described_class.tasks_dir).to eq described_class.root.join("lib", "donico", "rake", "tasks")
    end
  end

  describe ".default_commit_linter" do
    it "returns Donico root dir" do
      expect(described_class.default_commit_linter).to eq Donico::DEFAULT_COMMIT_LINTER
    end
  end

  describe ".default_docker_linter" do
    it "returns Donico root dir" do
      expect(described_class.default_docker_linter).to eq Donico::DEFAULT_DOCKER_LINTER
    end
  end

  describe ".config_file" do
    it "returns Donico config file path" do
      expect(described_class.config_file).to eq "#{Dir.pwd}/donico.yml"
    end
  end

  describe ".exec" do
    before { allow(Bundler).to receive(:original_env).and_return({ "FOO_VERSION" => "from-shell", "PATH" => "/usr/bin" }) }

    it "restores the original bundler environment" do
      expect(Kernel).to receive(:exec).with(hash_including("PATH" => "/usr/bin"), "true", { unsetenv_others: true })

      described_class.exec("true")
    end

    # A build arg is an explicit instruction from donico.yml; an inherited shell
    # variable of the same name (RUBY_VERSION, NODE_VERSION...) must not win over it.
    it "gives the explicit env precedence over the inherited environment" do
      expect(Kernel).to receive(:exec).with(hash_including("FOO_VERSION" => "from-build-arg"), "true", { unsetenv_others: true })

      described_class.exec("true", env: { "FOO_VERSION" => "from-build-arg" })
    end
  end

  describe ".load_config" do
    before { ENV["FOO"] = "BAR" }
    after  { ENV.delete("FOO") }

    let(:config) do
      {
        docker_registry:   "registry.example.net/images/base",
        docker_image_name: "foo",
        docker_image_tag:  nil,
        image_builder:     "docker",
        commit_linter:     Donico::DEFAULT_COMMIT_LINTER,
        docker_linter:     Donico::DEFAULT_DOCKER_LINTER,
        matrix:            [
          {
            distro:       "buster",
            dockerfile:   "Dockerfile",
            version:      "1.0.0",
            archs:        [
              "linux/amd64",
            ],
            build_args:   [
              "NODEJS_VERSION=14.17.3",
              "FOO=BAR",
            ],
            test_args:    [
              "RUBYGEM_VERSION=3.2.24",
            ],
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
        ],
      }
    end

    it "returns Donico config file path" do
      expect(described_class.load_config(get_fixture_path("docker/erb.yml")).to_h).to eq(config)
    end
  end
end
