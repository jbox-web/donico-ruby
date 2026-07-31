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

  describe "#secrets?" do
    it "is false when no secret is declared" do
      expect(image_named("foo").secrets?).to be false
    end
  end
end
