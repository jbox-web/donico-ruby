# frozen_string_literal: true

require "spec_helper"

RSpec.describe "donico.rake", type: :task do
  before { ENV.delete("CI_COMMIT_TIMESTAMP") }
  before { Donico.load_config(get_fixture_path("donico.yml")) }
  before { Donico.load_tasks }
  after  { Rake::Task.clear }

  let(:timestamp) { Time.now.strftime("%Y%m%d") }

  describe "amd64:buster:1.0.0:build" do
    it "build amd64:buster:1.0.0" do
      # setup test
      args = [hash_including, "docker", "build", "-f", "Dockerfile", "--pull", "--tag", "amd64/buster/foo-1.0.0:#{timestamp}", "--build-arg", "ARCH=amd64", "--build-arg", "DISTRO_NAME=buster", "--build-arg", "FOO_VERSION=1.0.0", ".", { unsetenv_others: true }]
      expect(Kernel).to receive(:exec).with(*args).and_return(true)

      # run the test
      Rake::Task["amd64:buster:1.0.0:build"].invoke
    end
  end

  describe "amd64:buster:1.0.0:test" do
    it "test amd64:buster:1.0.0" do
      # setup test
      args = [hash_including, "bin/inspec", "donico", "amd64/buster/foo-1.0.0:#{timestamp}", "foo_version=1.0.0", { unsetenv_others: true }]
      expect(Kernel).to receive(:exec).with(*args).and_return(true)

      # run the test
      Rake::Task["amd64:buster:1.0.0:test"].invoke
    end
  end

  describe "amd64:buster:1.0.0:tag" do
    it "tag amd64:buster:1.0.0" do
      # setup test
      args1 = ["docker", "tag", "amd64/buster/foo-1.0.0:#{timestamp}", "registry.example.net/images/base/foo:latest"]
      args2 = ["docker", "tag", "amd64/buster/foo-1.0.0:#{timestamp}", "registry.example.net/images/base/foo:1.0.0"]
      args3 = ["docker", "tag", "amd64/buster/foo-1.0.0:#{timestamp}", "registry.example.net/images/base/foo:1.0.0-buster"]
      expect(Donico::Tasks::Docker).to receive(:syscall).with(*args1).and_return(true)
      expect(Donico::Tasks::Docker).to receive(:syscall).with(*args2).and_return(true)
      expect(Donico::Tasks::Docker).to receive(:syscall).with(*args3).and_return(true)

      # run the test
      Rake::Task["amd64:buster:1.0.0:tag"].invoke
    end
  end

  describe "amd64:buster:1.0.0:push" do
    it "push amd64:buster:1.0.0" do
      # setup test
      args1 = ["docker", "push", "registry.example.net/images/base/foo:latest"]
      args2 = ["docker", "push", "registry.example.net/images/base/foo:1.0.0"]
      args3 = ["docker", "push", "registry.example.net/images/base/foo:1.0.0-buster"]
      expect(Donico::Tasks::Docker).to receive(:syscall).with(*args1).and_return(true)
      expect(Donico::Tasks::Docker).to receive(:syscall).with(*args2).and_return(true)
      expect(Donico::Tasks::Docker).to receive(:syscall).with(*args3).and_return(true)

      # run the test
      Rake::Task["amd64:buster:1.0.0:push"].invoke
    end
  end

  describe "amd64:buster:1.0.0:clean" do
    it "clean amd64:buster:1.0.0" do
      # setup test
      args = [hash_including, "docker", "rmi", "amd64/buster/foo-1.0.0:#{timestamp}", { unsetenv_others: true }]
      expect(Kernel).to receive(:exec).with(*args).and_return(true)

      # run the test
      Rake::Task["amd64:buster:1.0.0:clean"].invoke
    end
  end

  describe "amd64:buster:1.0.0:login" do
    it "login amd64:buster:1.0.0" do
      # setup test
      args = [hash_including, "docker", "run", "-it", "--rm", "amd64/buster/foo-1.0.0:#{timestamp}", "/bin/bash", { unsetenv_others: true }]
      expect(Kernel).to receive(:exec).with(*args).and_return(true)

      # run the test
      Rake::Task["amd64:buster:1.0.0:login"].invoke
    end
  end

end
