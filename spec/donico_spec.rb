# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico do
  describe ".root_dir" do
    it "returns Donico root dir" do
      expect(described_class.root_dir).to eq File.realpath(File.dirname(File.expand_path("../donico.gemspec", __dir__)))
    end
  end

  describe ".tasks_dir" do
    it "returns Donico tasks dir" do
      expect(described_class.tasks_dir).to eq described_class.root.join("lib", "donico", "rake", "tasks")
    end
  end

  describe ".default_commit_linter" do
    it "returns Donico root dir" do
      expect(described_class.default_commit_linter).to eq Donico::DEFAULT_COMMIT_LINTER
    end
  end

  describe ".default_docker_linter" do
    it "returns Donico root dir" do
      expect(described_class.default_docker_linter).to eq Donico::DEFAULT_DOCKER_LINTER
    end
  end

  describe ".config_file" do
    it "returns Donico config file path" do
      expect(described_class.config_file).to eq "#{Dir.pwd}/donico.yml"
    end
  end

  # Branching on defined?(RSpec) meant a consuming repo whose Rakefile loads RSpec
  # (to redefine the test task with a richer suite) silently lost all command
  # logging. The switch belongs to the environment, not to the test framework.
  describe ".log_args" do
    around do |example|
      previous = ENV.fetch("DONICO_QUIET", nil)
      example.run
      previous.nil? ? ENV.delete("DONICO_QUIET") : ENV["DONICO_QUIET"] = previous
    end

    it "logs the command by default" do
      ENV.delete("DONICO_QUIET")

      expect { described_class.log_args("exec", %w[docker build]) }.to output("exec: docker build\n").to_stdout
    end

    it "stays quiet when DONICO_QUIET is set" do
      ENV["DONICO_QUIET"] = "true"

      expect { described_class.log_args("exec", %w[docker build]) }.not_to output.to_stdout
    end
  end

  describe ".exec" do
    before { allow(Bundler).to receive(:original_env).and_return({ "FOO_VERSION" => "from-shell", "PATH" => "/usr/bin" }) }

    it "restores the original bundler environment" do
      expect(Kernel).to receive(:exec).with(hash_including("PATH" => "/usr/bin"), "true", { unsetenv_others: true })

      described_class.exec("true")
    end

    # A build arg is an explicit instruction from donico.yml; an inherited shell
    # variable of the same name (RUBY_VERSION, NODE_VERSION...) must not win over it.
    it "gives the explicit env precedence over the inherited environment" do
      expect(Kernel).to receive(:exec).with(hash_including("FOO_VERSION" => "from-build-arg"), "true", { unsetenv_others: true })

      described_class.exec("true", env: { "FOO_VERSION" => "from-build-arg" })
    end
  end

  describe ".load!" do
    it "loads the config then the tasks" do
      expect(described_class).to receive(:load_config).ordered
      expect(described_class).to receive(:load_tasks).ordered

      described_class.load!
    end
  end

  describe ".with_exit_status" do
    context "when the command succeeds" do
      it "exits successfully and yields the outcome" do
        allow(described_class).to receive(:system).and_return(true)
        expect(described_class).to receive(:exit).with(0)

        expect { |b| described_class.with_exit_status("true", &b) }.to yield_with_args(true)
      end
    end

    context "when the command fails" do
      it "exits with a failure status" do
        allow(described_class).to receive(:system).and_return(false)
        expect(described_class).to receive(:exit).with(1)

        described_class.with_exit_status("false")
      end
    end
  end

  describe ".run_cmd" do
    let(:status) { instance_double(Process::Status) }

    context "when the command succeeds" do
      it "returns the success flag and stdout" do
        allow(status).to receive(:success?).and_return(true)
        allow(Open3).to receive(:capture3).and_return(["out", "err", status])

        expect(described_class.run_cmd("true")).to eq [true, "out"]
      end
    end

    # Which stream carries the explanation depends on the command: docker reports
    # errors on stderr, hadolint reports its findings on stdout. Worse, `docker
    # run --pull always` writes its pull progress to stderr, so stderr is never
    # empty and a stdout-only fallback would still hide the findings. Return both.
    context "when the command fails" do
      it "returns stderr when stdout is empty" do
        allow(status).to receive(:success?).and_return(false)
        allow(Open3).to receive(:capture3).and_return(["", "err", status])

        expect(described_class.run_cmd("false")).to eq [false, "err"]
      end

      it "returns stdout when stderr is empty" do
        allow(status).to receive(:success?).and_return(false)
        allow(Open3).to receive(:capture3).and_return(["DL3006 always tag the version", "", status])

        expect(described_class.run_cmd("hadolint")).to eq [false, "DL3006 always tag the version"]
      end

      it "returns both streams when both carry something" do
        allow(status).to receive(:success?).and_return(false)
        allow(Open3).to receive(:capture3).and_return(["DL3006 always tag the version", "Pulling from jbox/base", status])

        success, log = described_class.run_cmd("hadolint")

        expect(success).to be false
        expect(log).to include("DL3006 always tag the version").and include("Pulling from jbox/base")
      end
    end

    it "yields the outcome when a block is given" do
      allow(status).to receive(:success?).and_return(true)
      allow(Open3).to receive(:capture3).and_return(["out", "err", status])

      expect { |b| described_class.run_cmd("true", &b) }.to yield_with_args(true)
    end

    # Returning a bare false here used to make the caller destructure log to nil,
    # which blew up later on nil.empty? instead of reporting the missing binary.
    context "when the command cannot be spawned" do
      it "returns the failure flag and the exception message" do
        allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT, "docker")

        success, log = described_class.run_cmd("docker")

        expect(success).to be false
        expect(log).to include("docker")
      end
    end
  end

  describe ".load_config" do
    before { ENV["FOO"] = "BAR" }
    after  { ENV.delete("FOO") }

    let(:config) do
      {
        docker_registry:   "registry.example.net/images/base",
        docker_image_name: "foo",
        docker_image_tag:  nil,
        image_builder:     "docker",
        commit_linter:     Donico::DEFAULT_COMMIT_LINTER,
        docker_linter:     Donico::DEFAULT_DOCKER_LINTER,
        matrix:            [
          {
            distro:       "buster",
            dockerfile:   "Dockerfile",
            version:      "1.0.0",
            archs:        [
              "linux/amd64",
            ],
            build_args:   [
              "NODEJS_VERSION=14.17.3",
              "FOO=BAR",
            ],
            test_args:    [
              "RUBYGEM_VERSION=3.2.24",
            ],
            secret_envs:  [],
            secret_files: [],
            tags:         [
              "latest",
              "%<version>s",
              "%<version>s-%<distro>s",
              "%<timestamp>s-%<distro>s",
              "%<version>s-%<timestamp>s-%<distro>s",
              "%<version>s-%<timestamp>s-%<distro>s-%<arch>s",
            ],
          },
        ],
      }
    end

    it "returns Donico config file path" do
      expect(described_class.load_config(get_fixture_path("docker/erb.yml")).to_h).to eq(config)
    end

    # Factoring a repetitive matrix with YAML anchors is the natural reflex, and
    # safe_load rejects them unless aliases are explicitly allowed.
    it "supports YAML anchors and aliases" do
      matrix = described_class.load_config(get_fixture_path("docker/aliases.yml")).matrix

      expect(matrix.map(&:version)).to eq %w[1.0.0 2.0.0]
      expect(matrix.map(&:distro)).to eq %w[buster buster]
    end

    it "rejects an empty config file with an explicit error" do
      expect do
        described_class.load_config(get_fixture_path("docker/empty.yml"))
      end.to raise_error(Donico::ConfigError, /empty/i)
    end

    it "raises when the config file is missing" do
      expect do
        described_class.load_config(get_fixture_path("docker/does-not-exist.yml"))
      end.to raise_error(Donico::ConfigError, /not found/i)
    end
  end
end
