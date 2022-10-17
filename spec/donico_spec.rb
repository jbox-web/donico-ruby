# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico do
  describe ".root_dir" do
    it "returns Donico root dir" do
      expect(Donico.root_dir).to eq File.realpath(File.dirname(File.expand_path("../donico.gemspec", __dir__)))
    end
  end

  describe ".tasks_dir" do
    it "returns Donico tasks dir" do
      expect(Donico.tasks_dir).to eq Donico.root.join("lib", "donico", "rake", "tasks")
    end
  end

  describe ".config_file" do
    it "returns Donico config file path" do
      expect(Donico.config_file).to eq "#{Dir.pwd}/donico.yml"
    end
  end

  describe ".load_config" do
    before { ENV["FOO"] = "BAR" }
    after  { ENV.delete("FOO") }

    it "returns Donico config file path" do
      expect(Donico.load_config(get_fixture_path("docker/erb.yml")).to_h).to eq({
                                                                                  docker_registry:   "registry.example.net/images/base",
                                                                                  docker_image_name: "foo",
                                                                                  docker_image_tag:  nil,
                                                                                  image_builder:     "docker",
                                                                                  commit_linter:     "harbor.jbox-cloud.fr/jbox/base/commitlint:latest",
                                                                                  docker_linter:     "harbor.jbox-cloud.fr/jbox/base/hadolint:latest",
                                                                                  matrix:            [
                                                                                    {
                                                                                      distro:     "buster",
                                                                                      dockerfile: "Dockerfile",
                                                                                      version:    "1.0.0",
                                                                                      archs:      [
                                                                                        "linux/amd64"
                                                                                      ],
                                                                                      build_args: [
                                                                                        "NODEJS_VERSION=14.17.3",
                                                                                        "FOO=BAR"
                                                                                      ],
                                                                                      test_args:  [
                                                                                        "RUBYGEM_VERSION=3.2.24"
                                                                                      ],
                                                                                      tags:       [
                                                                                        "latest",
                                                                                        "%<version>s",
                                                                                        "%<version>s-%<distro>s",
                                                                                        "%<timestamp>s-%<distro>s",
                                                                                        "%<version>s-%<timestamp>s-%<distro>s",
                                                                                        "%<version>s-%<timestamp>s-%<distro>s-%<arch>s"
                                                                                      ],
                                                                                    }
                                                                                  ],
                                                                                })
    end
  end
end
