# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Matrix do
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
