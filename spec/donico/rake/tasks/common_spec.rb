# frozen_string_literal: true

require "spec_helper"

RSpec.describe "common.rake", type: :task do
  context "when image_builder is donico" do
    before { Donico.load_config(get_fixture_path("donico_custom.yml")) }
    before { Donico.load_tasks }
    after  { Rake::Task.clear }

    describe "lint-dockerfile" do
      it "lint dockerfile" do
        args = ["docker", "run", "--pull", "always", "--rm", "-v", "#{Dir.pwd}:/app", "harbor.jbox-cloud.fr/jbox/base/hadolint:latest", "hadolint", "/app/Dockerfile"]
        expect(Donico).to receive(:with_exit_status).with(*args).and_yield(true)
        Rake::Task["lint-dockerfile"].invoke
      end
    end

    describe "lint-commits" do
      it "lint commits" do
        args = ["docker", "run", "--pull", "always", "--rm", "-v", "#{Dir.pwd}:/app", "harbor.jbox-cloud.fr/jbox/base/commitlint:latest", "commitlint", "/app"]
        expect(Donico).to receive(:with_exit_status).with(*args).and_yield(true)
        Rake::Task["lint-commits"].invoke
      end
    end
  end
end
