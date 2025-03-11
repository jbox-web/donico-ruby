# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Templates::Bakefile do
  before { Donico.load_config(get_fixture_path(fixture_file)) }

  describe "#render_template" do
    context "with minimal config file" do
      let(:fixture_file) { "bake/minimal.yml" }
      let(:generated_file) { "generated/bakefile/minimal.txt" }

      it "render template" do
        object = described_class.new
        expect(object.render).to eq File.read(get_fixture_path(generated_file))
      end
    end

    context "with custom config file" do
      let(:fixture_file) { "bake/custom.yml" }
      let(:generated_file) { "generated/bakefile/custom.txt" }

      it "render template" do
        object = described_class.new
        expect(object.render).to eq File.read(get_fixture_path(generated_file))
      end
    end

    context "with complex config file" do
      let(:fixture_file) { "bake/multiple_dockerfiles.yml" }
      let(:generated_file) { "generated/bakefile/multiple_dockerfiles.txt" }

      it "render template" do
        object = described_class.new
        expect(object.render).to eq File.read(get_fixture_path(generated_file))
      end
    end

    context "with debian config file" do
      let(:fixture_file) { "bake/debian.yml" }
      let(:generated_file) { "generated/bakefile/debian.txt" }

      it "render template" do
        object = described_class.new
        expect(object.render).to eq File.read(get_fixture_path(generated_file))
      end
    end
  end
end
