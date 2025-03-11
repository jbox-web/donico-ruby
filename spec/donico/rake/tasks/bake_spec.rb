# frozen_string_literal: true

require "spec_helper"

RSpec.describe "bake.rake", type: :task do
  before do
    ENV.delete("CI_COMMIT_TIMESTAMP")
    Donico.load_config(get_fixture_path(fixture_file))
    Donico.load_tasks
  end

  after do
    Rake::Task.clear
  end

  let(:timestamp) { Time.now.strftime("%Y%m%d") }

  context "with default configuration" do
    let(:version) { "latest" }
    let(:fixture_file) { "bake/minimal.yml" }

    describe "buster:latest:build" do
      let(:args) do
        [
          hash_including(
            "BUILD_DATE"  => timestamp,
            "DISTRO_NAME" => "buster",
            "FOO_VERSION" => version
          ),
          "docker",
          "buildx",
          "bake",
          "buster-#{version}-build",
          { unsetenv_others: true },
        ]
      end

      it "build buster:latest" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["buster:#{version}:build"].invoke
      end
    end

    describe "buster:latest:test" do
      let(:args) do
        [
          hash_including,
          "bin/inspec",
          "donico",
          "foo/#{version}/buster:#{timestamp}",
          "build_date=#{timestamp}",
          "distro_name=buster",
          "foo_version=#{version}",
          { unsetenv_others: true },
        ]
      end

      it "test buster:latest" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["buster:#{version}:test"].invoke
      end
    end

    describe "buster:latest:push" do
      let(:args) do
        [
          hash_including(
            "BUILD_DATE"  => timestamp,
            "DISTRO_NAME" => "buster",
            "FOO_VERSION" => version
          ),
          "docker",
          "buildx",
          "bake",
          "buster-#{version}-push",
          { unsetenv_others: true },
        ]
      end

      it "push buster:latest" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["buster:#{version}:push"].invoke
      end
    end

    describe "buster:latest:clean" do
      context "when command is success" do
        let(:args1) { ["docker", "rmi", "foo/#{version}/buster:#{timestamp}"] }
        let(:result) { instance_double(Process::Status) }

        it "clean buster:latest" do
          # setup test
          expect(result).to receive(:success?).once.and_return(true)
          allow(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["buster:#{version}:clean"].invoke
        end
      end

      context "when command is failure" do
        let(:args1) { ["docker", "rmi", "foo/#{version}/buster:#{timestamp}"] }
        let(:result) { instance_double(Process::Status) }

        it "doesn't clean buster:latest" do
          # setup test
          expect(result).to receive(:success?).once.and_return(false)
          allow(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["buster:#{version}:clean"].invoke
        end
      end
    end

    describe "buster:latest:login" do
      let(:args) do
        [
          hash_including,
          "docker",
          "run",
          "-it",
          "--rm",
          "foo/#{version}/buster:#{timestamp}",
          "/bin/bash",
          { unsetenv_others: true },
        ]
      end

      it "login buster:latest" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["buster:#{version}:login"].invoke
      end
    end
  end

  context "with custom configuration" do
    let(:version) { "1.0.0" }
    let(:fixture_file) { "bake/custom.yml" }

    describe "buster:1.0.0:build" do
      let(:args) do
        [
          hash_including(
            "BUILD_DATE"      => timestamp,
            "DISTRO_NAME"     => "buster",
            "FOO_BAR_VERSION" => version,
            "NODEJS_VERSION"  => "14.17.3"
          ),
          "docker",
          "buildx",
          "bake",
          "buster-#{version.tr('.', '-')}-build",
          { unsetenv_others: true },
        ]
      end

      it "build buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["buster:#{version}:build"].invoke
      end
    end

    describe "buster:1.0.0:test" do
      let(:args) do
        [
          hash_including,
          "bin/inspec",
          "donico",
          "foo-bar/#{version}/buster:#{timestamp}",
          "bar_version=zm9vcg==",
          "build_date=#{timestamp}",
          "distro_name=buster",
          "foo_bar_version=#{version}",
          "nodejs_version=14.17.3",
          "rubygem_version=3.2.24",
          { unsetenv_others: true },
        ]
      end

      it "test buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["buster:#{version}:test"].invoke
      end
    end

    describe "buster:1.0.0:push" do
      let(:args) do
        [
          hash_including(
            "BUILD_DATE"      => timestamp,
            "DISTRO_NAME"     => "buster",
            "FOO_BAR_VERSION" => version,
            "NODEJS_VERSION"  => "14.17.3"
          ),
          "docker",
          "buildx",
          "bake",
          "buster-#{version.tr('.', '-')}-push",
          { unsetenv_others: true },
        ]
      end

      it "push buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["buster:#{version}:push"].invoke
      end
    end

    describe "buster:1.0.0:clean" do
      context "when command is success" do
        let(:args1) { ["docker", "rmi", "foo-bar/#{version}/buster:#{timestamp}"] }
        let(:result) { instance_double(Process::Status) }

        it "clean buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).once.and_return(true)
          allow(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          allow(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["buster:#{version}:clean"].invoke
        end
      end

      context "when command is failure" do
        let(:args1) { ["docker", "rmi", "foo-bar/#{version}/buster:#{timestamp}"] }
        let(:result) { instance_double(Process::Status) }

        it "doesn't clean buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).once.and_return(false)
          allow(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          allow(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["buster:#{version}:clean"].invoke
        end
      end
    end

    describe "buster:1.0.0:login" do
      let(:args) do
        [
          hash_including,
          "docker",
          "run",
          "-it",
          "--rm",
          "foo-bar/#{version}/buster:#{timestamp}",
          "/bin/bash",
          { unsetenv_others: true },
        ]
      end

      it "login buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["buster:#{version}:login"].invoke
      end
    end
  end

  context "with debian configuration" do
    let(:version) { "latest" }
    let(:fixture_file) { "bake/debian.yml" }

    describe "bookworm:latest:build" do
      let(:args) do
        [
          hash_including(
            "BOOKWORM_VERSION" => "latest",
            "BUILD_DATE"       => timestamp,
            "DISTRO_NAME"      => "bookworm"
          ),
          "docker",
          "buildx",
          "bake",
          "bookworm-#{version}-build",
          { unsetenv_others: true },
        ]
      end

      it "build bookworm:latest" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["bookworm:#{version}:build"].invoke
      end
    end
  end
end
