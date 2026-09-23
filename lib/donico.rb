# frozen_string_literal: true

# Load std libs
require "fileutils"
require "open3"
require "pathname"
require "yaml"
require "time"
require "erb"

# Load external libs
require "bundler"
require "rake"
require "dotenv"

# Load our gem
require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

# Load version file
require_relative "donico/version"

module Donico
  module_function

  DEFAULT_COMMIT_LINTER = "harbor.thetuxhouse.org/jbox/base/commitlint:latest"
  DEFAULT_DOCKER_LINTER = "harbor.thetuxhouse.org/jbox/base/hadolint:latest"

  def load!
    load_config
    load_tasks
  end

  # Load Donico config
  def load_config(file = config_file)
    # Check config file presence
    raise ConfigError, "\nFile not found: donico.yml\nPlease create donico.yml at the project root.\n\n" unless File.exist?(file)

    @config = Config.new(load_config_file(file))
  end

  # SECURITY: donico.yml is evaluated as an ERB template BEFORE being parsed, which
  # is what makes `<%= ENV.fetch('FOO') %>` work in a config. safe_load therefore
  # guards against malicious YAML but not against the ERB running ahead of it:
  # whoever can edit donico.yml runs arbitrary code in the CI runner holding the
  # registry token. Deliberate and documented in the README; treat donico.yml as
  # code (review, CODEOWNERS).
  #
  # aliases: true because factoring a repetitive matrix with YAML anchors is the
  # natural reflex, and safe_load rejects them outright otherwise.
  def load_config_file(file)
    config = YAML.safe_load(ERB.new(File.read(file)).result, aliases: true)
    return config if config.is_a?(Hash)

    raise ConfigError, "\nEmpty or malformed donico.yml: expected a YAML mapping, got #{config.class}.\n\n"
  end

  # INVARIANT: one process serves one project directory. Dir.pwd is captured on the
  # first call and never revisited, so a later Dir.chdir is ignored.
  def config_file
    @config_file ||= File.expand_path(Pathname.new(Dir.pwd).join("donico.yml"))
  end

  # INVARIANT: one process serves one config. The parallelism comes from the GitLab
  # CI matrix (one job per process), never from several configs in flight here.
  def config
    @config
  end

  # Load Rake tasks by using Ruby *load* method
  #
  # record_task_metadata must be enabled BEFORE the tasks are declared: Rake leaves
  # it off during a normal run, which drops every `desc`. That is what forced the
  # help task to shell out to `rake -T`, and what made the before/after/redefine
  # hooks lose the description of the task they wrap.
  def load_tasks
    ::Rake::TaskManager.record_task_metadata = true

    tasks = ["#{tasks_dir}/common.rake", "#{tasks_dir}/#{config.image_builder}.rake"].sort
    tasks.map { |t| load(t) }
  end

  # Return a Pathname object so we can use nice methods on it :
  # Donico.root.join('tmp', 'foo', 'bar.yml')
  def root
    Pathname.new root_dir
  end

  # Set the lib root dir (the result is cached as it should not change)
  def root_dir
    @root_dir ||= File.realpath(File.dirname(File.expand_path("../donico.gemspec", __dir__)))
  end

  # Set the tasks root dir (the result is cached as it should not change)
  def tasks_dir
    @tasks_dir ||= root.join("lib", "donico", "rake", "tasks")
  end

  def default_commit_linter
    DEFAULT_COMMIT_LINTER
  end

  def default_docker_linter
    DEFAULT_DOCKER_LINTER
  end

  def images_list
    config.matrix.map { |m| Donico::Images::Base.build_image_from_matrix(matrix: m) }
  end

  # Silenced by DONICO_QUIET rather than by the presence of RSpec: a consuming repo
  # whose Rakefile loads RSpec (to redefine the test task with a richer Inspec
  # suite) used to lose all command logging without any way to get it back.
  def log_args(method, args)
    puts "#{method}: #{args.join(' ')}" unless ENV.key?("DONICO_QUIET")
  end

  def with_exit_status(*args)
    log_args("with_exit_status", args)

    success = system(*args)
    yield success if block_given?
    status = success ? 0 : 1
    exit(status)
  end

  # We need to cleanup env vars before executing any command
  # to avoid interferences with local environment.
  #
  # For example:
  # * donico gem uses ruby with it's own environment (asdf)
  # * chef inspec is coded in ruby and have it's own environment (somewhere in your fs)
  #
  # If any BUNDLER_* var is set before calling inspec (via bin/inspec),
  # your local install of inspec (not the docker one) will break with error like:
  # Could not find 'bundler' (2.2.19) required by `$BUNDLER_VERSION`.
  #
  # This happens because 'bin/inspec' is called via 'bin/rake *:test' which sets
  # such env vars. So clean them up before calling bin/inspec
  #
  # It should not harm to clean env vars before executing any command, so let's do it.
  def exec(*args, env: {})
    log_args("exec", args)

    # The explicit env wins: it carries the build args declared in donico.yml.
    # Merging the other way round let an inherited shell variable of the same name
    # (RUBY_VERSION, NODE_VERSION set by chruby/rvm/direnv...) silently override
    # them, building one version while tagging the image with another.
    env = Bundler.original_env.merge(env)
    Kernel.exec(env, *args, unsetenv_others: true)
  end

  # Which stream carries the explanation depends on the command: docker reports
  # errors on stderr, hadolint reports its findings on stdout. And `docker run
  # --pull always` writes its pull progress to stderr, so stderr is never empty
  # and returning it alone silently discarded the findings — the lint job failed
  # without printing a single reason. Return everything that was captured.
  def failure_output(stdout, stderr)
    [stdout, stderr].reject(&:empty?).join("\n")
  end

  def run_cmd(*args)
    log_args("run_cmd", args)

    begin
      stdout, stderr, status = Open3.capture3(*args)
      success = status.success?

      yield success if block_given?

      out = success ? stdout : failure_output(stdout, stderr)

      [success, out]
    rescue StandardError => e
      # Always return the same shape as the nominal path: callers destructure the
      # result, and a bare false left them with a nil log that blew up downstream
      # on nil.empty?, hiding the real cause (a missing docker binary, typically).
      [false, e.message]
    end
  end
end

# Load our hooks in Rake DSL
Rake::DSL.include(Donico::Rake::Hooks) if defined?(Rake::DSL)

# Load our hooks in mainObject
include Donico::Rake::Hooks unless self.class.include?(Donico::Rake::Hooks) # rubocop:disable Style/MixinUsage
