# frozen_string_literal: true

require "spec_helper"

RSpec.describe Donico::CommitRange do
  # The default predicate shells out to git; these examples decide themselves
  # which revisions the clone is supposed to hold.
  def base(env, exists: ->(_sha) { true })
    described_class.new(env, exists: exists).base
  end

  context "when GitLab runs the pipeline for a merge request" do
    it "starts from the base of the merge request" do
      expect(base({ "CI_MERGE_REQUEST_DIFF_BASE_SHA" => "aaa111" })).to eq "aaa111"
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
      expect(base({ "CI_COMMIT_BEFORE_SHA" => "bbb222" })).to eq "bbb222"
    end

    # GitLab reports forty zeroes rather than a parent on the first push of a
    # branch. Passed to --from, it makes commitlint fail on an unknown revision.
    it "falls back to the last commit on the first push of a branch" do
      expect(base({ "CI_COMMIT_BEFORE_SHA" => "0" * 40 })).to eq "HEAD~1"
    end

    it "falls back to the last commit when the variable is set but empty" do
      expect(base({ "CI_COMMIT_BEFORE_SHA" => "" })).to eq "HEAD~1"
    end
  end

  # The runner clones with `git depth 50`, so a base older than that is simply
  # not there. An amend or a force-push does worse: the SHA GitLab reports no
  # longer belongs to the branch at all, so no depth would bring it back. Either
  # way `git log <base>..HEAD` dies with "Invalid revision range" and the whole
  # lint stage fails on a range that was never the point.
  context "when the base is missing from the clone" do
    let(:absent) { ->(_sha) { false } }

    it "falls back to the last commit rather than naming an unknown revision" do
      expect(base({ "CI_COMMIT_BEFORE_SHA" => "bbb222" }, exists: absent)).to eq "HEAD~1"
    end

    it "falls back for a merge request base too" do
      expect(base({ "CI_MERGE_REQUEST_DIFF_BASE_SHA" => "aaa111" }, exists: absent)).to eq "HEAD~1"
    end

    # A merge request pipeline sets both. If the base of the merge request is out
    # of reach but the pushed one is there, that one is still better than HEAD~1.
    it "uses the pushed base when only the merge request one is missing" do
      env = { "CI_MERGE_REQUEST_DIFF_BASE_SHA" => "aaa111", "CI_COMMIT_BEFORE_SHA" => "bbb222" }
      reachable = ->(sha) { sha == "bbb222" }

      expect(base(env, exists: reachable)).to eq "bbb222"
    end
  end

  # The same task serves `bin/rake lint-commits` on a developer's machine, where
  # neither variable exists.
  context "when running outside CI" do
    it "falls back to the last commit" do
      expect(base({})).to eq "HEAD~1"
    end

    it "does not ask git about anything when there is no candidate" do
      asked = []

      base({}, exists: lambda { |sha|
        asked << sha
        true
      })

      expect(asked).to be_empty
    end
  end

  it "reads the real environment and the real repository by default" do
    expect(described_class.new.base).to be_a String
  end
end
