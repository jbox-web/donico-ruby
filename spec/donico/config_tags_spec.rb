# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Config do
  def config_for(tags, image_builder: "docker")
    described_class.new(
      "registry"      => "registry.example.net",
      "image_name"    => "foo",
      "image_builder" => image_builder,
      "matrix"        => [{ "version" => "1.0.0", "tags" => tags }]
    )
  end

  describe "tag macro validation" do
    it "accepts the documented macros on the docker backend" do
      expect { config_for(["%<version>s-%<distro>s-%<timestamp>s-%<arch>s"]) }.not_to raise_error
    end

    it "accepts a tag without any macro" do
      expect { config_for(["latest"]) }.not_to raise_error
    end

    # An unknown macro used to surface as a bare KeyError at tag time, with
    # nothing naming the offending tag.
    it "rejects an unknown macro" do
      expect { config_for(["%<foo>s"]) }.to raise_error(Donico::ConfigError, /%<foo>s.*arch.*distro.*timestamp.*version/m)
    end

    # Worse than an error: format() silently swallows a stray '%' and interpolates
    # the option hash, so "100%-slim" rendered as '100{version: "1.0.0"}lim'.
    it "rejects a literal percent sign" do
      expect { config_for(["100%-slim"]) }.to raise_error(Donico::ConfigError, /100%-slim/)
    end

    # bake resolves the platform list itself, so no single arch exists at tag time.
    it "rejects the arch macro on the bake backend" do
      expect { config_for(["%<version>s-%<arch>s"], image_builder: "bake") }.to raise_error(Donico::ConfigError, /arch/)
    end

    it "still accepts the other macros on the bake backend" do
      expect { config_for(["%<version>s-%<distro>s-%<timestamp>s"], image_builder: "bake") }.not_to raise_error
    end
  end
end
