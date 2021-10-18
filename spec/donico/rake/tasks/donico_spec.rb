# frozen_string_literal: true

require "spec_helper"

RSpec.describe "donico.rake", type: :task do
  before { ENV.delete("CI_COMMIT_TIMESTAMP") }
  before { Donico.load_config(get_fixture_path(fixture_file)) }
  before { Donico.load_tasks }
  after  { Rake::Task.clear }

  let(:timestamp) { Time.now.strftime("%Y%m%d") }

  context "with default configuration" do
    let(:version) { "latest" }
    let(:fixture_file) { "donico_minimal.yml" }

    describe "amd64:buster:latest:build" do
      it "build amd64:buster:latest" do
        # setup test
        args = [
          hash_including,
          "docker", "build",
          "-f", "Dockerfile",
          "--pull",
          "--tag", "amd64/buster/foo-#{version}:#{timestamp}",
          "--build-arg", "ARCH=amd64",
          "--build-arg", "DISTRO_NAME=buster",
          "--build-arg", "FOO_VERSION=#{version}",
          ".",
          { unsetenv_others: true }
        ]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["amd64:buster:#{version}:build"].invoke
      end
    end

    describe "amd64:buster:1.0.0:test" do
      it "test amd64:buster:1.0.0" do
        # setup test
        args = [
          hash_including,
          "bin/inspec",
          "donico",
          "amd64/buster/foo-#{version}:#{timestamp}",
          "arch=amd64",
          "distro_name=buster",
          "foo_version=#{version}",
          { unsetenv_others: true }
        ]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["amd64:buster:#{version}:test"].invoke
      end
    end

    describe "amd64:buster:1.0.0:tag" do
      context "when command is success" do
        it "tag amd64:buster:1.0.0" do
          # setup test
          args1 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-buster"]

          result = double("result")
          expect(result).to receive(:success?).exactly(2).times.and_return(true)
          expect(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["amd64:buster:#{version}:tag"].invoke
        end
      end

      context "when command is failure" do
        it "doesn't tag amd64:buster:1.0.0" do
          # setup test
          args1 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-buster"]

          result = double("result")
          expect(result).to receive(:success?).at_most(1).times.and_return(true)
          expect(result).to receive(:success?).at_most(1).times.and_return(false)
          expect(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["amd64:buster:#{version}:tag"].invoke
        end
      end
    end

    describe "amd64:buster:1.0.0:push" do
      context "when command is success" do
        it "push amd64:buster:1.0.0" do
          # setup test
          args1 = ["docker", "push", "registry.example.net/images/base/foo:#{version}-buster"]

          result = double("result")
          expect(result).to receive(:success?).exactly(2).times.and_return(true)
          expect(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["amd64:buster:#{version}:push"].invoke
        end
      end

      context "when command is failure" do
        it "doesn't push amd64:buster:1.0.0" do
          # setup test
          args1 = ["docker", "push", "registry.example.net/images/base/foo:#{version}-buster"]

          result = double("result")
          expect(result).to receive(:success?).at_most(1).times.and_return(true)
          expect(result).to receive(:success?).at_most(1).times.and_return(false)
          expect(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["amd64:buster:#{version}:push"].invoke
        end
      end
    end

    describe "amd64:buster:1.0.0:clean" do
      it "clean amd64:buster:1.0.0" do
        # setup test
        args = [hash_including, "docker", "rmi", "amd64/buster/foo-#{version}:#{timestamp}", { unsetenv_others: true }]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["amd64:buster:#{version}:clean"].invoke
      end
    end

    describe "amd64:buster:1.0.0:login" do
      it "login amd64:buster:1.0.0" do
        # setup test
        args = [hash_including, "docker", "run", "-it", "--rm", "amd64/buster/foo-#{version}:#{timestamp}", "/bin/bash", { unsetenv_others: true }]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["amd64:buster:#{version}:login"].invoke
      end
    end
  end

  context "with custom configuration" do
    let(:version) { "1.0.0" }
    let(:fixture_file) { "donico_custom.yml" }

    describe "amd64:buster:1.0.0:build" do
      it "build amd64:buster:1.0.0" do
        # setup test
        args = [
          hash_including,
          "docker", "build",
          "-f", "Dockerfile",
          "--pull",
          "--tag", "amd64/buster/foo-#{version}:#{timestamp}",
          "--build-arg", "ARCH=amd64",
          "--build-arg", "DISTRO_NAME=buster",
          "--build-arg", "FOO_VERSION=#{version}",
          "--build-arg", "NODEJS_VERSION=14.17.3",
          ".",
          { unsetenv_others: true }
        ]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["amd64:buster:#{version}:build"].invoke
      end
    end

    describe "amd64:buster:1.0.0:test" do
      it "test amd64:buster:1.0.0" do
        # setup test
        args = [
          hash_including,
          "bin/inspec",
          "donico",
          "amd64/buster/foo-#{version}:#{timestamp}",
          "arch=amd64",
          "distro_name=buster",
          "foo_version=#{version}",
          "nodejs_version=14.17.3",
          "rubygem_version=3.2.24",
          { unsetenv_others: true }
        ]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["amd64:buster:#{version}:test"].invoke
      end
    end

    describe "amd64:buster:1.0.0:tag" do
      context "when command is success" do
        it "tag amd64:buster:1.0.0" do
          # setup test
          args1 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:latest"]
          args2 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}"]
          args3 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-buster"]
          args4 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{timestamp}-buster"]
          args5 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster"]
          args6 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster-amd64"]

          result = double("result")
          expect(result).to receive(:success?).exactly(12).times.and_return(true)
          expect(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args2).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args3).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args4).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args5).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args6).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["amd64:buster:#{version}:tag"].invoke
        end
      end

      context "when command is failure" do
        it "doesn't tag amd64:buster:1.0.0" do
          # setup test
          args1 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:latest"]
          args2 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}"]
          args3 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-buster"]
          args4 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{timestamp}-buster"]
          args5 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster"]
          args6 = ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster-amd64"]

          result = double("result")
          expect(result).to receive(:success?).exactly(11).times.and_return(true)
          expect(result).to receive(:success?).at_most(1).times.and_return(false)
          expect(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args2).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args3).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args4).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args5).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args6).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["amd64:buster:#{version}:tag"].invoke
        end
      end
    end

    describe "amd64:buster:1.0.0:push" do
      context "when command is success" do
        it "push amd64:buster:1.0.0" do
          # setup test
          args1 = ["docker", "push", "registry.example.net/images/base/foo:latest"]
          args2 = ["docker", "push", "registry.example.net/images/base/foo:#{version}"]
          args3 = ["docker", "push", "registry.example.net/images/base/foo:#{version}-buster"]
          args4 = ["docker", "push", "registry.example.net/images/base/foo:#{timestamp}-buster"]
          args5 = ["docker", "push", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster"]
          args6 = ["docker", "push", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster-amd64"]

          result = double("result")
          expect(result).to receive(:success?).exactly(12).times.and_return(true)
          expect(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args2).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args3).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args4).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args5).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args6).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["amd64:buster:#{version}:push"].invoke
        end
      end

      context "when command is failure" do
        it "doesn't push amd64:buster:1.0.0" do
          # setup test
          args1 = ["docker", "push", "registry.example.net/images/base/foo:latest"]
          args2 = ["docker", "push", "registry.example.net/images/base/foo:#{version}"]
          args3 = ["docker", "push", "registry.example.net/images/base/foo:#{version}-buster"]
          args4 = ["docker", "push", "registry.example.net/images/base/foo:#{timestamp}-buster"]
          args5 = ["docker", "push", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster"]
          args6 = ["docker", "push", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster-amd64"]

          result = double("result")
          expect(result).to receive(:success?).exactly(11).times.and_return(true)
          expect(result).to receive(:success?).at_most(1).times.and_return(false)
          expect(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args2).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args3).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args4).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args5).and_return(["", "", result])
          expect(Open3).to receive(:capture3).with(*args6).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["amd64:buster:#{version}:push"].invoke
        end
      end
    end

    describe "amd64:buster:1.0.0:clean" do
      it "clean amd64:buster:1.0.0" do
        # setup test
        args = [hash_including, "docker", "rmi", "amd64/buster/foo-#{version}:#{timestamp}", { unsetenv_others: true }]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["amd64:buster:#{version}:clean"].invoke
      end
    end

    describe "amd64:buster:1.0.0:login" do
      it "login amd64:buster:1.0.0" do
        # setup test
        args = [hash_including, "docker", "run", "-it", "--rm", "amd64/buster/foo-#{version}:#{timestamp}", "/bin/bash", { unsetenv_others: true }]
        expect(Kernel).to receive(:exec).with(*args).and_return(true)

        # run the test
        Rake::Task["amd64:buster:#{version}:login"].invoke
      end
    end
  end
end
