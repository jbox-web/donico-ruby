# frozen_string_literal: true

require "spec_helper"

RSpec.describe "common.rake", type: :task do
  context "when image_builder is docker" do
    context "when single Dockerfile is used" do
      before { Donico.load_config(get_fixture_path("docker/minimal.yml")) }
      before { Donico.load_tasks }
      after  { Rake::Task.clear }

      describe "lint-dockerfile" do
        it "lint dockerfile" do
          args = ["docker", "run", "--pull", "always", "--rm", "-v", "#{Dir.pwd}:/app", Donico::DEFAULT_DOCKER_LINTER, "hadolint", "/app/Dockerfile"]
          # return false to not pollute stdout but we could also have returned true
          expect(Donico).to receive(:run_cmd).with(*args).and_yield(false)
          Rake::Task["lint-dockerfile"].invoke
        end
      end
    end

    context "when multiple Dockerfiles are used" do
      before { Donico.load_config(get_fixture_path("docker/multiple_dockerfiles.yml")) }
      before { Donico.load_tasks }
      after  { Rake::Task.clear }

      describe "lint-dockerfile" do
        it "lint dockerfile" do
          args = ["docker", "run", "--pull", "always", "--rm", "-v", "#{Dir.pwd}:/app", Donico::DEFAULT_DOCKER_LINTER, "hadolint", "/app/dockerfiles/3.1/Dockerfile"]
          # return false to not pollute stdout but we could also have returned true
          expect(Donico).to receive(:run_cmd).with(*args).and_yield(false)

          args = ["docker", "run", "--pull", "always", "--rm", "-v", "#{Dir.pwd}:/app", Donico::DEFAULT_DOCKER_LINTER, "hadolint", "/app/dockerfiles/3.2/Dockerfile"]
          # return false to not pollute stdout but we could also have returned true
          expect(Donico).to receive(:run_cmd).with(*args).and_yield(false)

          Rake::Task["lint-dockerfile"].invoke
        end
      end
    end

    describe "lint-commits" do
      before { Donico.load_config(get_fixture_path("docker/minimal.yml")) }
      before { Donico.load_tasks }
      after  { Rake::Task.clear }

      it "lint commits" do
        args = ["docker", "run", "--pull", "always", "--rm", "-v", "#{Dir.pwd}:/app", Donico::DEFAULT_COMMIT_LINTER, "commitlint", "/app"]
        expect(Donico).to receive(:with_exit_status).with(*args).and_yield(false)
        Rake::Task["lint-commits"].invoke
      end
    end
  end
end
