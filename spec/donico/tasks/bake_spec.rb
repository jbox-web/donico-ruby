# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Tasks::Bake do
  before { Donico.load_config(get_fixture_path(fixture_file)) }

  describe ".generate_earthfile" do
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
