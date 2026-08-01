# frozen_string_literal: true

require "spec_helper"

RSpec.describe "docker.rake", type: :task do
  before do
    Donico.load_config(get_fixture_path(fixture_file))
    Donico.load_tasks
  end

  after { Rake::Task.clear }

  let(:timestamp) { Time.now.strftime("%Y%m%d") }

  context "with default configuration" do
    let(:version) { "latest" }
    let(:fixture_file) { "docker/minimal.yml" }

    describe "amd64:buster:latest:build" do
      let(:args) do
        [
          hash_including,
          "docker", "build",
          "-f", "Dockerfile",
          "--pull",
          "--tag", "amd64/buster/foo-#{version}:#{timestamp}",
          "--build-arg", "ARCH=amd64",
          "--build-arg", "BUILD_DATE=#{timestamp}",
          "--build-arg", "DISTRO_NAME=buster",
          "--build-arg", "FOO_VERSION=#{version}",
          ".",
          { unsetenv_others: true },
        ]
      end

      it "build amd64:buster:latest" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["amd64:buster:#{version}:build"].invoke
      end
    end

    describe "amd64:buster:1.0.0:test" do
      let(:args) do
        [
          hash_including,
          "bin/inspec",
          "donico",
          "amd64/buster/foo-#{version}:#{timestamp}",
          "arch=amd64",
          "build_date=#{timestamp}",
          "distro_name=buster",
          "foo_version=#{version}",
          { unsetenv_others: true },
        ]
      end

      it "test amd64:buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["amd64:buster:#{version}:test"].invoke
      end
    end

    describe "amd64:buster:1.0.0:tag" do
      context "when command is success" do
        let(:args) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-buster"] }
        let(:result) { instance_double(Process::Status) }

        it "tag amd64:buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).once.and_return(true)
          allow(Open3).to receive(:capture3).with(*args).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["amd64:buster:#{version}:tag"].invoke
        end
      end

      context "when command is failure" do
        let(:args) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-buster"] }
        let(:result) { instance_double(Process::Status) }

        it "doesn't tag amd64:buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).once.and_return(false)
          allow(Open3).to receive(:capture3).with(*args).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["amd64:buster:#{version}:tag"].invoke
        end

        # The captured stderr is the only clue the user gets about why the tag
        # failed, so it has to reach stdout rather than be swallowed.
        it "prints what docker reported" do
          allow(result).to receive(:success?).and_return(false)
          allow(Open3).to receive(:capture3).with(*args).and_return(["", "No such image", result])
          allow(Kernel).to receive(:exit).with(1)

          expect { Rake::Task["amd64:buster:#{version}:tag"].invoke }.to output(/No such image/).to_stdout
        end
      end
    end

    describe "amd64:buster:1.0.0:push" do
      context "when command is success" do
        let(:args) { ["docker", "push", "registry.example.net/images/base/foo:#{version}-buster"] }
        let(:result) { instance_double(Process::Status) }

        it "push amd64:buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).once.and_return(true)
          allow(Open3).to receive(:capture3).with(*args).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["amd64:buster:#{version}:push"].invoke
        end
      end

      context "when command is failure" do
        let(:args) { ["docker", "push", "registry.example.net/images/base/foo:#{version}-buster"] }
        let(:result) { instance_double(Process::Status) }

        it "doesn't push amd64:buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).once.and_return(false)
          allow(Open3).to receive(:capture3).with(*args).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["amd64:buster:#{version}:push"].invoke
        end
      end
    end

    describe "amd64:buster:1.0.0:clean" do
      let(:args) { [hash_including, "docker", "rmi", "amd64/buster/foo-#{version}:#{timestamp}", { unsetenv_others: true }] }

      it "clean amd64:buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["amd64:buster:#{version}:clean"].invoke
      end
    end

    describe "amd64:buster:1.0.0:login" do
      let(:args) do
        [
          hash_including,
          "docker",
          "run",
          "-it",
          "--rm",
          "amd64/buster/foo-#{version}:#{timestamp}",
          "/bin/bash",
          { unsetenv_others: true },
        ]
      end

      it "login amd64:buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["amd64:buster:#{version}:login"].invoke
      end
    end
  end

  context "with custom configuration" do
    let(:version) { "1.0.0" }
    let(:fixture_file) { "docker/custom.yml" }

    describe "amd64:buster:1.0.0:build" do
      let(:args) do
        [
          hash_including,
          "docker", "build",
          "-f", "foo/Dockerfile",
          "--pull",
          "--tag", "amd64/buster/foo-#{version}:#{timestamp}",
          "--build-arg", "ARCH=amd64",
          "--build-arg", "BUILD_DATE=#{timestamp}",
          "--build-arg", "DISTRO_NAME=buster",
          "--build-arg", "FOO_VERSION=#{version}",
          "--build-arg", "NODEJS_VERSION=14.17.3",
          ".",
          { unsetenv_others: true },
        ]
      end

      it "build amd64:buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["amd64:buster:#{version}:build"].invoke
      end
    end

    describe "amd64:buster:1.0.0:test" do
      let(:args) do
        [
          hash_including,
          "bin/inspec",
          "donico",
          "amd64/buster/foo-#{version}:#{timestamp}",
          "arch=amd64",
          "build_date=#{timestamp}",
          "distro_name=buster",
          "foo_version=#{version}",
          "nodejs_version=14.17.3",
          "rubygem_version=3.2.24",
          { unsetenv_others: true },
        ]
      end

      it "test amd64:buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["amd64:buster:#{version}:test"].invoke
      end
    end

    describe "amd64:buster:1.0.0:tag" do
      context "when command is success" do
        let(:args1) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:latest"] }
        let(:args2) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}"] }
        let(:args3) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-buster"] }
        let(:args4) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{timestamp}-buster"] }
        let(:args5) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster"] }
        let(:args6) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster-amd64"] }
        let(:result) { instance_double(Process::Status) }

        it "tag amd64:buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).exactly(6).times.and_return(true)
          allow(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args2).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args3).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args4).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args5).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args6).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["amd64:buster:#{version}:tag"].invoke
        end
      end

      context "when command is failure" do
        let(:args1) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:latest"] }
        let(:args2) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}"] }
        let(:args3) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-buster"] }
        let(:args4) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{timestamp}-buster"] }
        let(:args5) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster"] }
        let(:args6) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster-amd64"] }
        let(:result) { instance_double(Process::Status) }

        it "doesn't tag amd64:buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).exactly(5).times.and_return(true)
          expect(result).to receive(:success?).at_most(:once).and_return(false)
          allow(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args2).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args3).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args4).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args5).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args6).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["amd64:buster:#{version}:tag"].invoke
        end
      end
    end

    describe "amd64:buster:1.0.0:push" do
      context "when command is success" do
        let(:args1) { ["docker", "push", "registry.example.net/images/base/foo:latest"] }
        let(:args2) { ["docker", "push", "registry.example.net/images/base/foo:#{version}"] }
        let(:args3) { ["docker", "push", "registry.example.net/images/base/foo:#{version}-buster"] }
        let(:args4) { ["docker", "push", "registry.example.net/images/base/foo:#{timestamp}-buster"] }
        let(:args5) { ["docker", "push", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster"] }
        let(:args6) { ["docker", "push", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster-amd64"] }
        let(:result) { instance_double(Process::Status) }

        it "push amd64:buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).exactly(6).times.and_return(true)
          allow(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args2).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args3).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args4).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args5).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args6).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["amd64:buster:#{version}:push"].invoke
        end
      end

      context "when command is failure" do
        let(:args1) { ["docker", "push", "registry.example.net/images/base/foo:latest"] }
        let(:args2) { ["docker", "push", "registry.example.net/images/base/foo:#{version}"] }
        let(:args3) { ["docker", "push", "registry.example.net/images/base/foo:#{version}-buster"] }
        let(:args4) { ["docker", "push", "registry.example.net/images/base/foo:#{timestamp}-buster"] }
        let(:args5) { ["docker", "push", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster"] }
        let(:args6) { ["docker", "push", "registry.example.net/images/base/foo:#{version}-#{timestamp}-buster-amd64"] }
        let(:result) { instance_double(Process::Status) }

        it "doesn't push amd64:buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).exactly(5).times.and_return(true)
          expect(result).to receive(:success?).at_most(:once).and_return(false)
          allow(Open3).to receive(:capture3).with(*args1).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args2).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args3).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args4).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args5).and_return(["", "", result])
          allow(Open3).to receive(:capture3).with(*args6).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["amd64:buster:#{version}:push"].invoke
        end
      end
    end

    describe "amd64:buster:1.0.0:clean" do
      let(:args) { [hash_including, "docker", "rmi", "amd64/buster/foo-#{version}:#{timestamp}", { unsetenv_others: true }] }

      it "clean amd64:buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["amd64:buster:#{version}:clean"].invoke
      end
    end

    describe "amd64:buster:1.0.0:login" do
      let(:args) { [hash_including, "docker", "run", "-it", "--rm", "amd64/buster/foo-#{version}:#{timestamp}", "/bin/bash", { unsetenv_others: true }] }

      it "login amd64:buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["amd64:buster:#{version}:login"].invoke
      end
    end
  end

  context "with old arch syntax" do
    let(:version) { "1.0.0" }
    let(:fixture_file) { "docker/deprecated_archs.yml" }

    describe "amd64:buster:latest:build" do
      let(:args) do
        [
          hash_including,
          "docker", "build",
          "-f", "Dockerfile",
          "--pull",
          "--tag", "amd64/buster/foo-#{version}:#{timestamp}",
          "--build-arg", "ARCH=amd64",
          "--build-arg", "BUILD_DATE=#{timestamp}",
          "--build-arg", "DISTRO_NAME=buster",
          "--build-arg", "FOO_VERSION=#{version}",
          ".",
          { unsetenv_others: true },
        ]
      end

      it "build amd64:buster:latest" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["amd64:buster:#{version}:build"].invoke
      end
    end

    describe "amd64:buster:1.0.0:test" do
      let(:args) do
        [
          hash_including,
          "bin/inspec",
          "donico",
          "amd64/buster/foo-#{version}:#{timestamp}",
          "arch=amd64",
          "build_date=#{timestamp}",
          "distro_name=buster",
          "foo_version=#{version}",
          { unsetenv_others: true },
        ]
      end

      it "test amd64:buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["amd64:buster:#{version}:test"].invoke
      end
    end

    describe "amd64:buster:1.0.0:tag" do
      context "when command is success" do
        let(:args) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-buster"] }
        let(:result) { instance_double(Process::Status) }

        it "tag amd64:buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).once.and_return(true)
          allow(Open3).to receive(:capture3).with(*args).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["amd64:buster:#{version}:tag"].invoke
        end
      end

      context "when command is failure" do
        let(:args) { ["docker", "tag", "amd64/buster/foo-#{version}:#{timestamp}", "registry.example.net/images/base/foo:#{version}-buster"] }
        let(:result) { instance_double(Process::Status) }

        it "doesn't tag amd64:buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).once.and_return(false)
          allow(Open3).to receive(:capture3).with(*args).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["amd64:buster:#{version}:tag"].invoke
        end
      end
    end

    describe "amd64:buster:1.0.0:push" do
      context "when command is success" do
        let(:args) { ["docker", "push", "registry.example.net/images/base/foo:#{version}-buster"] }
        let(:result) { instance_double(Process::Status) }

        it "push amd64:buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).once.and_return(true)
          allow(Open3).to receive(:capture3).with(*args).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(0)

          # run the test
          Rake::Task["amd64:buster:#{version}:push"].invoke
        end
      end

      context "when command is failure" do
        let(:args) { ["docker", "push", "registry.example.net/images/base/foo:#{version}-buster"] }
        let(:result) { instance_double(Process::Status) }

        it "doesn't push amd64:buster:1.0.0" do
          # setup test
          expect(result).to receive(:success?).once.and_return(false)
          allow(Open3).to receive(:capture3).with(*args).and_return(["", "", result])
          expect(Kernel).to receive(:exit).with(1)

          # run the test
          Rake::Task["amd64:buster:#{version}:push"].invoke
        end
      end
    end

    describe "amd64:buster:1.0.0:clean" do
      let(:args) { [hash_including, "docker", "rmi", "amd64/buster/foo-#{version}:#{timestamp}", { unsetenv_others: true }] }

      it "clean amd64:buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["amd64:buster:#{version}:clean"].invoke
      end
    end

    describe "amd64:buster:1.0.0:login" do
      let(:args) { [hash_including, "docker", "run", "-it", "--rm", "amd64/buster/foo-#{version}:#{timestamp}", "/bin/bash", { unsetenv_others: true }] }

      it "login amd64:buster:1.0.0" do
        # setup test
        expect(Kernel).to receive(:exec).with(*args)

        # run the test
        Rake::Task["amd64:buster:#{version}:login"].invoke
      end
    end
  end
end
