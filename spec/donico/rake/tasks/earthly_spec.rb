# frozen_string_literal: true

require "spec_helper"

RSpec.describe "earthly.rake", type: :task do
  before { ENV.delete("CI_COMMIT_TIMESTAMP") }
  before { Donico.load_config(get_fixture_path(fixture_file)) }
  before { Donico.load_tasks }
  after  { Rake::Task.clear }

  let(:timestamp) { Time.now.strftime("%Y%m%d") }

  context "with default configuration" do
    let(:version) { "latest" }
    let(:fixture_file) { "earthly/minimal.yml" }

    describe "buster:latest:build" do
      it "build buster:latest" do
        # setup test
        args = [
          hash_including,
          "earthly",
          "--ci",
          "--output",
          "--build-arg", "BUILD_DATE=#{timestamp}",
          "--build-arg", "DISTRO_NAME=buster",
          "--build-arg", "FOO_VERSION=#{version}",
          "+buster-#{version}-build",
          { unsetenv_others: true },
        ]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["buster:#{version}:build"].invoke
      end
    end

    describe "buster:latest:test" do
      it "test buster:latest" do
        # setup test
        args = [
          hash_including,
          "bin/inspec",
          "donico",
          "foo/#{version}/buster:#{timestamp}",
          "build_date=#{timestamp}",
          "distro_name=buster",
          "foo_version=#{version}",
          { unsetenv_others: true },
        ]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["buster:#{version}:test"].invoke
      end
    end

    describe "buster:latest:push" do
      it "push buster:latest" do
        # setup test
        args = [
          hash_including,
          "earthly",
          "--ci",
          "--output",
          "--push",
          "--build-arg", "BUILD_DATE=#{timestamp}",
          "--build-arg", "DISTRO_NAME=buster",
          "--build-arg", "FOO_VERSION=#{version}",
          "+buster-#{version}-push",
          { unsetenv_others: true },
        ]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["buster:#{version}:push"].invoke
      end
    end

    describe "buster:latest:clean" do
      context "when command is success" do
        it "clean buster:latest" do
          # setup test
          args1 = ["docker", "rmi", "foo/#{version}/buster:#{timestamp}"]
          args2 = ["docker", "rmi", "foo/#{version}/buster:#{timestamp}_linux_amd64"]

          result = double("result")
          expect(result).to receive(:success?).exactly(2).times.and_return(true)
          expect(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args2).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["buster:#{version}:clean"].invoke
        end
      end

      context "when command is failure" do
        it "doesn't clean buster:latest" do
          # setup test
          args1 = ["docker", "rmi", "foo/#{version}/buster:#{timestamp}"]
          args2 = ["docker", "rmi", "foo/#{version}/buster:#{timestamp}_linux_amd64"]

          result = double("result")
          expect(result).to receive(:success?).exactly(1).times.and_return(true)
          expect(result).to receive(:success?).exactly(1).times.and_return(false)
          expect(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args2).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["buster:#{version}:clean"].invoke
        end
      end
    end

    describe "buster:latest:login" do
      it "login buster:latest" do
        # setup test
        args = [hash_including, "docker", "run", "-it", "--rm", "foo/#{version}/buster:#{timestamp}", "/bin/bash", { unsetenv_others: true }]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["buster:#{version}:login"].invoke
      end
    end
  end

  context "with custom configuration" do
    let(:version) { "1.0.0" }
    let(:fixture_file) { "earthly/custom.yml" }

    describe "buster:1.0.0:build" do
      it "build buster:1.0.0" do
        # setup test
        args = [
          hash_including,
          "earthly",
          "--ci",
          "--output",
          "--build-arg", "BUILD_DATE=#{timestamp}",
          "--build-arg", "DISTRO_NAME=buster",
          "--build-arg", "FOO_BAR_VERSION=#{version}",
          "--build-arg", "NODEJS_VERSION=14.17.3",
          "+buster-#{version}-build",
          { unsetenv_others: true },
        ]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["buster:#{version}:build"].invoke
      end
    end

    describe "buster:1.0.0:test" do
      it "test buster:1.0.0" do
        # setup test
        args = [
          hash_including,
          "bin/inspec",
          "donico",
          "foo-bar/#{version}/buster:#{timestamp}",
          "build_date=#{timestamp}",
          "distro_name=buster",
          "foo_bar_version=#{version}",
          "nodejs_version=14.17.3",
          "rubygem_version=3.2.24",
          { unsetenv_others: true },
        ]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["buster:#{version}:test"].invoke
      end
    end

    describe "buster:1.0.0:push" do
      it "push buster:1.0.0" do
        # setup test
        args = [
          hash_including,
          "earthly",
          "--ci",
          "--output",
          "--push",
          "--build-arg", "BUILD_DATE=#{timestamp}",
          "--build-arg", "DISTRO_NAME=buster",
          "--build-arg", "FOO_BAR_VERSION=#{version}",
          "--build-arg", "NODEJS_VERSION=14.17.3",
          "+buster-#{version}-push",
          { unsetenv_others: true },
        ]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["buster:#{version}:push"].invoke
      end
    end

    describe "buster:1.0.0:clean" do
      context "when command is success" do
        it "clean buster:1.0.0" do
          # setup test
          args1 = ["docker", "rmi", "foo-bar/#{version}/buster:#{timestamp}"]
          args2 = ["docker", "rmi", "foo-bar/#{version}/buster:#{timestamp}_linux_amd64"]

          result = double("result")
          expect(result).to receive(:success?).exactly(2).times.and_return(true)
          expect(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args2).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["buster:#{version}:clean"].invoke
        end
      end

      context "when command is failure" do
        it "doesn't clean buster:1.0.0" do
          # setup test
          args1 = ["docker", "rmi", "foo-bar/#{version}/buster:#{timestamp}"]
          args2 = ["docker", "rmi", "foo-bar/#{version}/buster:#{timestamp}_linux_amd64"]

          result = double("result")
          expect(result).to receive(:success?).exactly(1).times.and_return(true)
          expect(result).to receive(:success?).exactly(1).times.and_return(false)
          expect(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args2).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["buster:#{version}:clean"].invoke
        end
      end
    end

    describe "buster:1.0.0:login" do
      it "login buster:1.0.0" do
        # setup test
        args = [hash_including, "docker", "run", "-it", "--rm", "foo-bar/#{version}/buster:#{timestamp}", "/bin/bash", { unsetenv_others: true }]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["buster:#{version}:login"].invoke
      end
    end
  end

  context "with debian configuration" do
    let(:version) { "latest" }
    let(:fixture_file) { "earthly/debian.yml" }

    describe "bookworm:latest:build" do
      it "build bookworm:latest" do
        # setup test
        args = [
          hash_including,
          "earthly",
          "--ci",
          "--output",
          "--build-arg", "BOOKWORM_VERSION=latest",
          "--build-arg", "BUILD_DATE=#{timestamp}",
          "--build-arg", "DISTRO_NAME=bookworm",
          "+bookworm-#{version}-build",
          { unsetenv_others: true },
        ]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["bookworm:#{version}:build"].invoke
      end
    end
  end
end
