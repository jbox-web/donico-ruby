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
          "--build-arg", "DISTRO_NAME=buster",
          "--build-arg", "FOO_VERSION=#{version}",
          "--build-arg", "TIMESTAMP=#{timestamp}",
          "+buster-#{version}-build-all",
          { unsetenv_others: true }
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
          "foo/#{version}/buster:#{timestamp}",
          "distro_name=buster",
          "foo_version=#{version}",
          { unsetenv_others: true }
        ]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["buster:#{version}:test"].invoke
      end
    end

    describe "buster:1.0.0:push" do
      it "push buster:latest" do
        # setup test
        args = [
          hash_including,
          "earthly",
          "--push",
          "--build-arg", "DISTRO_NAME=buster",
          "--build-arg", "FOO_VERSION=#{version}",
          "--build-arg", "TIMESTAMP=#{timestamp}",
          "+buster-#{version}-push-all",
          { unsetenv_others: true }
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
        it "doesn't clean buster:1.0.0" do
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

    describe "buster:1.0.0:login" do
      it "login buster:1.0.0" do
        # setup test
        args = [hash_including, "docker", "run", "-it", "--rm", "foo/#{version}/buster:#{timestamp}", "/bin/bash", { unsetenv_others: true }]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["buster:#{version}:login"].invoke
      end
    end
  end
end
