# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What Donico is

Donico is a Ruby gem that turns a single `donico.yml` file into a matrix of Rake
tasks for building, testing, tagging, pushing and cleaning Docker images — both
locally and in GitLab CI. It is *consumed* by other repos (each Docker image repo
adds a `Rakefile` that calls `Donico.load!`); this repo is the gem's own source.

Two build backends are supported, selected via the `image_builder` config key
(default `docker`):
- `docker` — classic `docker build`, one arch per task, tasks namespaced
  `<arch>:<distro>:<version>:<action>`.
- `bake` — `docker buildx bake` (multi-arch), tasks namespaced
  `<distro>:<version>:<action>`, and `generate-files` renders a `docker-bake.hcl`.

## Commands (developing the gem)

`mise.toml` defines the canonical dev tasks:

```sh
mise dev:deps          # bundle install
mise dev:test          # bin/rspec  (full suite, fails under 88% line coverage)
mise dev:lint-project  # bin/rubocop
mise dev:lint-shell    # shellcheck -x on bash/, exe/inspec, bin/push
mise dev:lint-commits  # commitlint in a container (conventional commits)
mise dev:build         # bin/rake build DONICO_RELEASE=true
```

Tasks are namespaced `dev:*` on purpose: an unprefixed name can be shadowed by a
mise subcommand. `mise deps` used to resolve to mise's own experimental `deps`
subcommand instead of the project task, silently skipping `bundle install` and
failing every CI job on `Bundler::GemNotFound`.

Run a single spec / example:

```sh
bin/rspec spec/donico/config_spec.rb
bin/rspec spec/donico/config_spec.rb:42
```

`DONICO_RELEASE=true` makes `Rakefile` skip loading RSpec (release-only mode) —
needed when building the gem, since the release environment lacks rspec.

## Architecture

`lib/donico.rb` is the entry point. `Donico.load!` does two things:
1. `load_config` — reads `donico.yml` (run through ERB, then `YAML.safe_load`)
   into a `Config` object.
2. `load_tasks` — `load`s `common.rake` plus the backend-specific rake file
   (`docker.rake` or `bake.rake`) based on `config.image_builder`.

Autoloading is via **Zeitwerk** (`Zeitwerk::Loader.for_gem`), so every file under
`lib/donico/` must match the `Donico::` namespace by path — no manual `require`s
for gem code.

The object pipeline, from config to shell command:

```
donico.yml
  └─ Config              lib/donico/config.rb    top-level keys + timestamp logic
       └─ Matrix (list)  lib/donico/matrix.rb    one entry per matrix row; also
                                                 writes .gitlab-ci/extends/.matrix.yml
            └─ Images::{Docker,Bake}  lib/donico/images/   tag/build-arg formatting,
               (< Images::Base)                            backend-specific
                 └─ Tasks::{Docker,Bake}  lib/donico/tasks/  actual docker/buildx
                    (< Tasks::Base)                          commands run via Donico.exec
```

- `Images::Base.build_image_from_matrix` picks the concrete class from the
  explicit `IMAGE_CLASSES` table (`lib/donico/images/base.rb`).
- `Config` validates the whole file at load time and raises `Donico::ConfigError`
  (`lib/donico/config_error.rb`) with a user-facing message: supported
  `image_builder`, resolvable `image_name`, tag macros allowed for the backend,
  well-formed secrets. `Matrix` refuses a `version` YAML coerced into a number.
- The `*.rake` files are *generators*: they iterate `Donico.config.matrix` and
  dynamically declare namespaced Rake tasks (`arch → distro → version → action`).
  The task bodies just delegate to `Donico::Tasks::*`.
- `common.rake` holds backend-agnostic tasks: `lint-dockerfile`, `lint-commits`,
  `generate-files`, `version`, `help` (the default task).
- `Templates::Bakefile` renders `lib/donico/data/templates/bakefile.erb` into
  `docker-bake.hcl` for the bake backend.

### Command execution helpers (in `lib/donico.rb`)

- `Donico.exec` — replaces the process (`Kernel.exec`) with `unsetenv_others:
  true`, restoring `Bundler.original_env` **then** merging the explicit `env` on
  top so build args win over inherited shell variables. This deliberately scrubs
  `BUNDLER_*` env vars so nested Ruby tools (notably `bin/inspec`) don't inherit
  Donico's bundler context — see the long comment there before touching it.
  Because it replaces the process, an `after` hook on an exec-based task never
  runs (documented in `hooks.rb` and the README).
- `Donico.run_cmd` — captures output via `Open3.capture3`, always returns
  `[success, output]`, including on the rescue path (used when multiple commands
  run and results are aggregated).
- Command logging is silenced by `DONICO_QUIET`, not by detecting RSpec.
- `Donico.with_exit_status` — `system` + `exit`.

### Hooks (`lib/donico/rake/hooks.rb`)

`before` / `after` / `redefine` are mixed into `Rake::DSL` and the main object, so
consuming repos' `Rakefile`s can wrap or replace any generated task. They work by
deleting the existing task from `Rake.application` and redefining it — this is how
the Donico Docker image hooks `before` a task to fetch the gem, and how consumers
`redefine` the `test` task for richer Inspec suites.

### Inspec test harness

`exe/inspec` (the gem's only executable) + `bash/donico.lib.sh` spin a container
and run Chef Inspec tests against a freshly built image. `Tasks::*#test` shells out
to `bin/inspec donico <build_tag> <test_args>`.

## Conventions

- Ruby ≥ 3.3 required (`donico.gemspec`); toolchain pinned to 3.4.9 via `mise.toml`.
- RuboCop enforced (`rubocop-performance`, `-rake`, `-rspec`); double-quoted
  strings, table-aligned hashes. `bin/*` is excluded from linting.
- Commits must be **Conventional Commits** (`commitlint`, enforced in CI).
- CI (`.gitlab-ci.yml`) runs `mise <job-name>` for each stage
  (lint → test → build → push); `push` publishes the gem to the GitLab package
  registry, and only on tags.

## Gotchas

- The `README.md` is the user-facing doc for *consumers*. It was realigned with
  the code on 2026-07-31 (audit `AUDIT-2026-07-31.md`): the task listing is the
  verbatim output of a real run and every `donico.yml` snippet loads through
  `Donico.load_config`. Regenerate the listing rather than editing it by hand.
- `version` must be quoted in `donico.yml`: YAML turns `3.10` into the Float 3.1.
  `Matrix` now rejects a non-String version rather than silently mis-tagging.
- `Donico.load_tasks` turns on `Rake::TaskManager.record_task_metadata`, which
  Rake leaves off during a normal run. Without it every `desc` is dropped, which
  is why `help` used to shell out to `rake -T` and why the hooks lost the
  description of the task they wrap.
- Bumping the version means editing `lib/donico/version.rb` only — the gemspec and
  everything else read `Donico::VERSION::STRING` from it.
