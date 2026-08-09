# frozen_string_literal: true

module Donico
  # Which commits `lint-commits` hands to commitlint.
  #
  # Up to commitlint 12, invoking `commitlint /app` with no range worked by
  # accident: the positional argument is ignored, and with neither --from, --to
  # nor --edit the CLI fell back to reading the whole git history. That fallback
  # is gone from v13 on — commitlint then reads stdin, which is closed in CI, so
  # it lints the empty string and fails on every commit. The range has to be
  # explicit, and --from/--to is the one form both the old and the new CLI accept.
  #
  # The base depends on how the pipeline was triggered:
  #
  #   merge request  CI_MERGE_REQUEST_DIFF_BASE_SHA
  #   push           CI_COMMIT_BEFORE_SHA
  #   neither        HEAD~1
  #
  # Both variables are set on a merge request pipeline, hence the order: the push
  # one points at the previous head of the source branch and would skip the very
  # commits the merge request adds.
  #
  # Every candidate is checked against the repository before being used. GitLab
  # names a commit; it does not promise the runner has it. The clone is made with
  # `git depth 50`, so anything older is absent, and an amend or a force-push is
  # worse still: the reported SHA no longer belongs to the branch, so no depth
  # would bring it back. Handing such a base to commitlint ends the job on
  # "fatal: Invalid revision range <sha>..HEAD" — a lint failure that says nothing
  # about the commit messages.
  class CommitRange
    # What GitLab reports instead of a parent on the first push of a branch.
    NULL_SHA = ("0" * 40).freeze

    # Also what a developer gets locally, where neither variable exists.
    FALLBACK = "HEAD~1"

    def self.base(env = ENV, **) = new(env, **).base

    def initialize(env = ENV, exists: nil)
      @env    = env
      @exists = exists || method(:reachable?)
    end

    # nil when even the fallback is out of reach, which means HEAD is the root
    # commit — a squashed or a brand new repository. There is no range to lint
    # then, only the one commit, and the caller has to say so differently:
    # HEAD~1..HEAD ends the job on "ambiguous argument 'HEAD~1..HEAD'".
    def base
      reachable(merge_request_base) || reachable(push_base) || reachable(FALLBACK)
    end

    private

    def merge_request_base = presence("CI_MERGE_REQUEST_DIFF_BASE_SHA")

    def push_base
      sha = presence("CI_COMMIT_BEFORE_SHA")
      sha unless sha == NULL_SHA
    end

    def reachable(sha)
      sha if sha && @exists.call(sha)
    end

    # `^{commit}` so a SHA that happens to name a blob or a tree is rejected too.
    def reachable?(sha)
      system("git", "cat-file", "-e", "#{sha}^{commit}", out: File::NULL, err: File::NULL)
    end

    # A GitLab variable can be defined and empty, which is not a revision either.
    def presence(key)
      value = @env[key].to_s.strip
      value unless value.empty?
    end
  end
end
