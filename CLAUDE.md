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
mise deps          # bundle install
mise test          # bin/rspec  (full suite)
mise lint-project  # bin/rubocop
mise lint-commits  # commitlint in a container (conventional commits)
mise build         # bin/rake build DONICO_RELEASE=true
```

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

- `Images::Base.build_image_from_matrix` picks the concrete class by
  `image_builder.capitalize` and instantiates it via `Donico::Utils.constantize`
  (a vendored ActiveSupport-style `constantize`, `lib/donico/utils.rb`).
- The `*.rake` files are *generators*: they iterate `Donico.config.matrix` and
  dynamically declare namespaced Rake tasks (`arch → distro → version → action`).
  The task bodies just delegate to `Donico::Tasks::*`.
- `common.rake` holds backend-agnostic tasks: `lint-dockerfile`, `lint-commits`,
  `generate-files`, `version`, `help` (the default task).
- `Templates::Bakefile` renders `lib/donico/data/templates/bakefile.erb` into
  `docker-bake.hcl` for the bake backend.

### Command execution helpers (in `lib/donico.rb`)

- `Donico.exec` — replaces the process (`Kernel.exec`) with `unsetenv_others:
  true`, restoring only `Bundler.original_env`. This deliberately scrubs
  `BUNDLER_*` env vars so nested Ruby tools (notably `bin/inspec`) don't inherit
  Donico's bundler context — see the long comment there before touching it.
- `Donico.run_cmd` — captures output via `Open3.capture3`, returns
  `[success, output]` (used when multiple commands run and results are aggregated).
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

- The `README.md` is the user-facing doc for *consumers*. Task names, registry
  host (`harbor.jbox-cloud.fr/jbox/base`) and CI templates were realigned with the
  code; a few illustrative snippets may still lag behind exact flag output, so
  trust the code for authoritative task names and defaults.
- Bumping the version means editing `lib/donico/version.rb` only — the gemspec and
  everything else read `Donico::VERSION::STRING` from it.
