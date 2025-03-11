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

  DEFAULT_COMMIT_LINTER = "harbor.jbox-cloud.fr/jbox/base/commitlint:latest"
  DEFAULT_DOCKER_LINTER = "harbor.jbox-cloud.fr/jbox/base/hadolint:latest"

  def load!
    load_config
    load_tasks
  end

  # Load Donico config
  def load_config(file = config_file)
    # Check config file presence
    raise "\nFile not found: donico.yml\nPlease create donico.yml at the project root.\n\n" unless File.exist?(file)

    @config = Config.new(load_config_file(file))
  end

  def load_config_file(file)
    YAML.safe_load(ERB.new(File.read(file)).result)
  end

  def config_file
    @config_file ||= File.expand_path(Pathname.new(Dir.pwd).join("donico.yml"))
  end

  def config
    @config
  end

  # Load Rake tasks by using Ruby *load* method
  def load_tasks
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

  def log_args(method, args)
    puts "#{method}: #{args.join(' ')}" unless defined?(RSpec)
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

    env = env.merge(Bundler.original_env)
    Kernel.exec(env, *args, unsetenv_others: true)
  end

  # rubocop:disable Metrics/MethodLength
  def run_cmd(*args)
    log_args("run_cmd", args)

    begin
      stdout, stderr, status = Open3.capture3(*args)
      success = status.success?

      yield success if block_given?

      out = success ? stdout : stderr

      [success, out]
    rescue StandardError => e
      puts e
      false
    end
  end
  # rubocop:enable Metrics/MethodLength
end

# Load our hooks in Rake DSL
Rake::DSL.include(Donico::Rake::Hooks) if defined?(Rake::DSL)

# Load our hooks in mainObject
include Donico::Rake::Hooks unless self.class.included_modules.include?(Donico::Rake::Hooks) # rubocop:disable Style/MixinUsage
