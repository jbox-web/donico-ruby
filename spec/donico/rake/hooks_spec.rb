# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::Rake::Hooks do
  # The hooks are mixed into Rake::DSL and into the main object, which is exactly
  # how a consuming repo uses them from its Rakefile.
  let(:dsl) { Object.new.extend(Rake::DSL).extend(described_class) }
  let(:calls) { [] }

  after { Rake::Task.clear }

  def define_task(name, into:, prerequisites: [])
    recorder = into
    dsl.instance_eval do
      desc "original description"
      task name => prerequisites do
        recorder << :original
      end
    end
  end

  describe "#before" do
    it "runs the new block before the original task" do
      define_task(:build, into: calls)
      recorder = calls
      dsl.before(:build) { recorder << :hook }

      Rake::Task["build"].invoke

      expect(calls).to eq %i[hook original]
    end

    # Rake only attaches descriptions when record_task_metadata is on, which is the
    # case whenever rake actually loads a Rakefile, but not by default in specs.
    it "keeps the description and the prerequisites of the original task" do
      Rake::TaskManager.record_task_metadata = true
      define_task(:deps, into: calls)
      define_task(:build, into: calls, prerequisites: [:deps])
      dsl.before(:build) { nil }

      expect(Rake::Task["build"].full_comment).to eq "original description"
      expect(Rake::Task["build"].prerequisites).to eq ["deps"]
    ensure
      Rake::TaskManager.record_task_metadata = false
    end
  end

  describe "#after" do
    it "runs the new block after the original task" do
      define_task(:build, into: calls)
      recorder = calls
      dsl.after(:build) { recorder << :hook }

      Rake::Task["build"].invoke

      expect(calls).to eq %i[original hook]
    end

    it "propagates an exception raised by the original task" do
      dsl.instance_eval { task(:build) { raise "boom" } }
      dsl.after(:build) { nil }

      expect { Rake::Task["build"].invoke }.to raise_error(RuntimeError, "boom")
    end

    it "swallows the exception when ignore_exceptions is set" do
      dsl.instance_eval { task(:build) { raise "boom" } }
      recorder = calls
      dsl.after(:build, ignore_exceptions: true) { recorder << :hook }

      expect { Rake::Task["build"].invoke }.not_to raise_error
      expect(calls).to eq [:hook]
    end
  end

  describe "#redefine" do
    it "replaces the body of the original task" do
      define_task(:build, into: calls)
      recorder = calls
      dsl.redefine(:build) { recorder << :replacement }

      Rake::Task["build"].invoke

      expect(calls).to eq [:replacement]
    end
  end
end
