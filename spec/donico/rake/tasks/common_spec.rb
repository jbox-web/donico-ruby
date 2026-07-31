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

        it "exits successfully when hadolint reports no violation" do
          allow(Donico).to receive(:run_cmd).with(*args).and_return([true, ""])
          expect(Kernel).to receive(:exit).with(0)

          Rake::Task["lint-dockerfile"].invoke
        end

        # A linter whose result is never inspected makes the CI job green whatever
        # the Dockerfile contains, which is worse than having no linter at all.
        it "exits with a failure status when hadolint reports a violation" do
          allow(Donico).to receive(:run_cmd).with(*args).and_return([false, "DL3008 pin versions"])
          expect(Kernel).to receive(:exit).with(1)

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

        it "lints every dockerfile and fails as soon as one is rejected" do
          allow(Donico).to receive(:run_cmd).with(*args1).and_return([true, ""])
          allow(Donico).to receive(:run_cmd).with(*args2).and_return([false, "DL3008 pin versions"])
          expect(Kernel).to receive(:exit).with(1)

          Rake::Task["lint-dockerfile"].invoke
        end
      end
    end

    # The CI template used to pick its branch with `grep -q bake donico.yml`, which
    # matches the string anywhere in the file: an image_name like "bakery" or a
    # comment was enough to route a docker build through the bake code path.
    describe "image-builder" do
      before do
        Donico.load_config(get_fixture_path("docker/minimal.yml"))
        Donico.load_tasks
      end

      after { Rake::Task.clear }

      it "prints the configured backend and nothing else" do
        expect { Rake::Task["image-builder"].invoke }.to output("docker\n").to_stdout
      end
    end

    # help used to shell out to `rake -T`, spawning a second Ruby that reloaded
    # donico.yml, re-evaluated its ERB and rebuilt the whole matrix, and printed
    # an empty usage block without a word if rake was not on the subshell PATH.
    describe "help" do
      before do
        Donico.load_config(get_fixture_path("docker/minimal.yml"))
        Donico.load_tasks
      end

      after { Rake::Task.clear }

      it "lists the described tasks without spawning a subprocess" do
        expect(Donico).not_to receive(:`)

        expect { Rake::Task["help"].invoke }.to output(
          include("Usage:")
          .and(match(%r{bin/rake amd64:buster:latest:build\s+# Build docker image}))
          .and(match(%r{bin/rake lint-dockerfile\s+# Lint Dockerfile}))
        ).to_stdout
      end

      it "does not list itself" do
        expect { Rake::Task["help"].invoke }.not_to output(%r{bin/rake help}).to_stdout
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
