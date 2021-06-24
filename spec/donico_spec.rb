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
end
