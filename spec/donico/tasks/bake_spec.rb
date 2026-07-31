# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Tasks::Bake do
  before { Donico.load_config(get_fixture_path(fixture_file)) }

  # Tasks::Base exposes .tag for every backend, but bake produces its tags itself
  # at push time. Inheriting it silently promised a method that did not exist.
  describe ".tag" do
    let(:fixture_file) { "bake/minimal.yml" }

    it "states that the bake backend tags at push time" do
      image = Donico::Images::Base.build_image_from_matrix(matrix: Donico.config.matrix.first)

      expect { described_class.tag(image) }.to raise_error(NotImplementedError, /bake.*push/im)
    end
  end

  describe ".generate_bakefile" do
    let(:fixture_file) { "bake/custom.yml" }

    it "generates a valid Bakefile" do
      # don't write file for real
      allow_any_instance_of(Donico::Templates::Bakefile).to receive(:write).with(no_args).and_return(true) # rubocop:disable RSpec/AnyInstance

      bakefile = described_class.generate_bakefile
      expect(bakefile.template).to eq Donico.root.join("lib/donico/data/templates/bakefile.erb")
      expect(bakefile.file).to eq "docker-bake.hcl"
      expect(bakefile.data).to match({ images: array_including(instance_of(Donico::Images::Bake)) })
    end
  end
end
