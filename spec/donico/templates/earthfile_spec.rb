# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Templates::Earthfile do
  before { Donico.load_config(get_fixture_path(fixture_file)) }

  describe "#render_template" do
    context "with minimal config file" do
      let(:fixture_file) { "earthly/minimal.yml" }
      let(:generated_file) { "generated/earthfile_minimal.txt" }

      it "render template" do
        object = described_class.new
        expect(object.render).to eq File.read(get_fixture_path(generated_file))
      end
    end

    context "with custom config file" do
      let(:fixture_file) { "earthly/custom.yml" }
      let(:generated_file) { "generated/earthfile_custom.txt" }

      it "render template" do
        object = described_class.new
        expect(object.render).to eq File.read(get_fixture_path(generated_file))
      end
    end

    context "with complex config file" do
      let(:fixture_file) { "earthly/multiple_dockerfiles.yml" }
      let(:generated_file) { "generated/earthfile_multiple_dockerfiles.txt" }

      it "render template" do
        object = described_class.new
        expect(object.render).to eq File.read(get_fixture_path(generated_file))
      end
    end
  end
end
