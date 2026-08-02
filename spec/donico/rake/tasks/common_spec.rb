# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe "common.rake", type: :task do
  # generate-files writes into the working directory, so every example runs in a
  # throwaway one rather than littering the repo.
  def in_tmpdir(&)
    Dir.mktmpdir { |dir| Dir.chdir(dir, &) }
  end

  describe "version" do
    before do
      Donico.load_config(get_fixture_path("docker/minimal.yml"))
      Donico.load_tasks
    end

    after { Rake::Task.clear }

    it "prints the gem version" do
      expect { Rake::Task["version"].invoke }.to output("#{Donico.gem_version}\n").to_stdout
    end
  end

  describe "generate-files" do
    after { Rake::Task.clear }

    context "with the docker backend" do
      before do
        Donico.load_config(get_fixture_path("docker/minimal.yml"))
        Donico.load_tasks
      end

      it "writes the CI matrix and no bakefile" do
        in_tmpdir do
          expect { Rake::Task["generate-files"].invoke }.to output(/no Bakefile/i).to_stdout

          expect(File).to exist(".gitlab-ci/extends/.matrix.yml")
          expect(File).not_to exist("docker-bake.hcl")
        end
      end
    end

    context "with the bake backend" do
      before do
        Donico.load_config(get_fixture_path("bake/minimal.yml"))
        Donico.load_tasks
      end

      it "writes both the CI matrix and the bakefile" do
        in_tmpdir do
          expect { Rake::Task["generate-files"].invoke }.to output(/Bakefile generated/).to_stdout

          expect(File).to exist(".gitlab-ci/extends/.matrix.yml")
          expect(File).to exist("docker-bake.hcl")
        end
      end
    end
  end

  context "when image_builder is docker" do
    context "when single Dockerfile is used" do
      before do
        Donico.load_config(get_fixture_path("docker/minimal.yml"))
        Donico.load_tasks
      end

      after { Rake::Task.clear }

      describe "lint-dockerfile" do
        let(:args) { ["docker", "run", "--pull", "always", "--rm", "-e", "MISE_IGNORED_CONFIG_PATHS=/app/mise.toml", "-v", "#{Dir.pwd}:/app", Donico::DEFAULT_DOCKER_LINTER, "hadolint", "/app/Dockerfile"] }

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
        let(:args1) { ["docker", "run", "--pull", "always", "--rm", "-e", "MISE_IGNORED_CONFIG_PATHS=/app/mise.toml", "-v", "#{Dir.pwd}:/app", Donico::DEFAULT_DOCKER_LINTER, "hadolint", "/app/dockerfiles/3.1/Dockerfile"] }
        let(:args2) { ["docker", "run", "--pull", "always", "--rm", "-e", "MISE_IGNORED_CONFIG_PATHS=/app/mise.toml", "-v", "#{Dir.pwd}:/app", Donico::DEFAULT_DOCKER_LINTER, "hadolint", "/app/dockerfiles/3.2/Dockerfile"] }

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

      let(:args) do
        ["docker", "run", "--pull", "always", "--rm", "-e", "MISE_IGNORED_CONFIG_PATHS=/app/mise.toml", "-v", "#{Dir.pwd}:/app", Donico::DEFAULT_COMMIT_LINTER,
         "commitlint", "--from", base, "--to", "HEAD", "--verbose",]
      end

      # A real revision of this repository, because CommitRange checks the base
      # against the clone before using it: a made-up SHA would be refused, and the
      # examples below would assert the fallback while claiming to assert the
      # range.
      let(:existing_sha) { %x(git rev-parse HEAD).strip }

      context "when running outside CI" do
        let(:base) { "HEAD~1" }

        it "lint commits" do
          expect(Donico).to receive(:with_exit_status).with(*args)

          Rake::Task["lint-commits"].invoke
        end
      end

      # The task reads the real environment, so the range follows the pipeline it
      # runs in. Both variables are cleared by spec_helper's volatile_env list:
      # without that, this suite would pick up whatever GitLab exports while
      # linting donico itself, and the example above would fail in CI only.
      context "when GitLab runs a push pipeline" do
        let(:base) { existing_sha }

        before { ENV["CI_COMMIT_BEFORE_SHA"] = base }

        it "starts from the commit the branch was on before the push" do
          expect(Donico).to receive(:with_exit_status).with(*args)

          Rake::Task["lint-commits"].invoke
        end
      end

      context "when GitLab runs a merge request pipeline" do
        let(:base) { existing_sha }

        before { ENV["CI_MERGE_REQUEST_DIFF_BASE_SHA"] = base }

        it "starts from the base of the merge request" do
          expect(Donico).to receive(:with_exit_status).with(*args)

          Rake::Task["lint-commits"].invoke
        end
      end

      # What actually broke the donico image pipeline: an amend had rewritten the
      # head, so the SHA GitLab reported was no longer on the branch and the
      # shallow clone did not hold it. commitlint died on "Invalid revision
      # range", failing the lint stage for a reason unrelated to any message.
      context "when GitLab names a commit the clone does not have" do
        let(:base) { "HEAD~1" }

        before { ENV["CI_COMMIT_BEFORE_SHA"] = "afd4b44c8a8912b9d64bb1e2b169995d08e3bcdf" }

        it "falls back to the last commit" do
          expect(Donico).to receive(:with_exit_status).with(*args)

          Rake::Task["lint-commits"].invoke
        end
      end
    end
  end
end
