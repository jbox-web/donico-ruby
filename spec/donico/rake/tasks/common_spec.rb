# frozen_string_literal: true

require "spec_helper"

RSpec.describe "common.rake", type: :task do
  context "when image_builder is docker" do
    context "when single Dockerfile is used" do
      before do
        Donico.load_config(get_fixture_path("docker/minimal.yml"))
        Donico.load_tasks
      end

      after { Rake::Task.clear }

      describe "lint-dockerfile" do
        let(:args) { ["docker", "run", "--pull", "always", "--rm", "-v", "#{Dir.pwd}:/app", Donico::DEFAULT_DOCKER_LINTER, "hadolint", "/app/Dockerfile"] }

        it "lint dockerfile" do
          # return false to not pollute stdout but we could also have returned true
          expect(Donico).to receive(:run_cmd).with(*args)

          Rake::Task["lint-dockerfile"].invoke
        end
      end
    end

    context "when multiple Dockerfiles are used" do
      before do
        Donico.load_config(get_fixture_path("docker/multiple_dockerfiles.yml"))
        Donico.load_tasks
      end

      after { Rake::Task.clear }

      describe "lint-dockerfile" do
        let(:args1) { ["docker", "run", "--pull", "always", "--rm", "-v", "#{Dir.pwd}:/app", Donico::DEFAULT_DOCKER_LINTER, "hadolint", "/app/dockerfiles/3.1/Dockerfile"] }
        let(:args2) { ["docker", "run", "--pull", "always", "--rm", "-v", "#{Dir.pwd}:/app", Donico::DEFAULT_DOCKER_LINTER, "hadolint", "/app/dockerfiles/3.2/Dockerfile"] }

        it "lint dockerfile" do
          # return false to not pollute stdout but we could also have returned true
          expect(Donico).to receive(:run_cmd).with(*args1)

          # return false to not pollute stdout but we could also have returned true
          expect(Donico).to receive(:run_cmd).with(*args2)

          Rake::Task["lint-dockerfile"].invoke
        end
      end
    end

    describe "lint-commits" do
      before do
        Donico.load_config(get_fixture_path("docker/minimal.yml"))
        Donico.load_tasks
      end

      after { Rake::Task.clear }

      let(:args) { ["docker", "run", "--pull", "always", "--rm", "-v", "#{Dir.pwd}:/app", Donico::DEFAULT_COMMIT_LINTER, "commitlint", "/app"] }

      it "lint commits" do
        expect(Donico).to receive(:with_exit_status).with(*args)

        Rake::Task["lint-commits"].invoke
      end
    end
  end
end
