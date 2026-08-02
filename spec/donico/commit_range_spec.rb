# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::CommitRange do
  def base(env) = described_class.new(env).base

  context "when GitLab runs the pipeline for a merge request" do
    it "starts from the base of the merge request" do
      expect(base("CI_MERGE_REQUEST_DIFF_BASE_SHA" => "aaa111")).to eq "aaa111"
    end

    # Both variables are set on a merge request pipeline. The push one points at
    # the previous head of the source branch, so it would skip the commits the
    # merge request is actually adding.
    it "prefers the merge request base over the pushed range" do
      env = { "CI_MERGE_REQUEST_DIFF_BASE_SHA" => "aaa111", "CI_COMMIT_BEFORE_SHA" => "bbb222" }

      expect(base(env)).to eq "aaa111"
    end
  end

  context "when GitLab runs the pipeline for a push" do
    it "starts from the commit the branch was on before the push" do
      expect(base("CI_COMMIT_BEFORE_SHA" => "bbb222")).to eq "bbb222"
    end

    # GitLab reports forty zeroes rather than a parent on the first push of a
    # branch. Passed to --from, it makes commitlint fail on an unknown revision.
    it "falls back to the last commit on the first push of a branch" do
      expect(base("CI_COMMIT_BEFORE_SHA" => "0" * 40)).to eq "HEAD~1"
    end

    it "falls back to the last commit when the variable is set but empty" do
      expect(base("CI_COMMIT_BEFORE_SHA" => "")).to eq "HEAD~1"
    end
  end

  # The same task serves `bin/rake lint-commits` on a developer's machine, where
  # neither variable exists.
  context "when running outside CI" do
    it "falls back to the last commit" do
      expect(base({})).to eq "HEAD~1"
    end
  end

  it "reads the real environment by default" do
    expect(described_class.new.base).to be_a String
  end
end
