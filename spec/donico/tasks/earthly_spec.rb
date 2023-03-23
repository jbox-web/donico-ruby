# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Tasks::Earthly do
  before { Donico.load_config(get_fixture_path(fixture_file)) }

  describe ".generate_earthfile" do
    let(:fixture_file) { "earthly/custom.yml" }

    it "generates a valid Earthfile" do
      # don't write file for real
      expect_any_instance_of(Donico::Templates::Earthfile).to receive(:write).with(no_args).and_return(true)

      earthfile = Donico::Tasks::Earthly.generate_earthfile
      expect(earthfile.template).to eq Donico.root.join("lib/donico/data/templates/earthfile.erb")
      expect(earthfile.file).to eq "Earthfile"
      expect(earthfile.data).to match({ images: array_including(instance_of(Donico::Images::Earthly)), earthly_version: "0.7" })
    end
  end
end
