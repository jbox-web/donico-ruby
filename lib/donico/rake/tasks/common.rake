# frozen_string_literal: true

################
# LINT section #
################

# The linter images are mise-based, and mise reads the config of the directory it
# starts in. Mounting the project at /app made it parse the project's own
# mise.toml, which is untrusted there and may use a syntax newer than the mise
# shipped in the linter image: the container aborted before the linter ever ran.
# Every image repository of the fleet carries a mise.toml, so every one was hit.
#
# Ignoring that file is the direct expression of what we want: the linter has no
# business provisioning the project's toolchain.
MISE_IGNORE = ["-e", "MISE_IGNORED_CONFIG_PATHS=/app/mise.toml"].freeze

desc "Lint Dockerfile"
task :"lint-dockerfile" do
  results = []
  logs    = []

  Donico.config.dockerfiles.each do |f|
    # -w / as a second guard, independent of the mise version: hadolint takes an
    # absolute path, so it does not care about the working directory. commitlint
    # does (it runs git from there), which is why it only gets the env var.
    success, log = Donico.run_cmd("docker", "run", "--pull", "always", "--rm", *MISE_IGNORE, "-w", "/", "-v", "#{Dir.pwd}:/app", Donico.config.docker_linter, "hadolint", f)
    results << success
    logs << log
  end

  # The linter result must drive the exit status, otherwise the CI job stays green
  # whatever the Dockerfile contains and the lint stage is purely decorative.
  if results.include?(false)
    puts logs.compact.reject(&:empty?).join("\n")
    Kernel.exit(1)
  else
    puts "Dockerfile is OK!"
    Kernel.exit(0)
  end
end

desc "Lint commits"
task :"lint-commits" do
  Donico.with_exit_status("docker", "run", "--pull", "always", "--rm", *MISE_IGNORE, "-v", "#{Dir.pwd}:/app", Donico.config.commit_linter, "commitlint", "/app") do |success|
    puts("Commits are OK!") if success
  end
end


###################
# RELEASE section #
###################

desc "Generate GitlabCI matrix and Bakefile"
task :"generate-files" do
  Donico::Matrix.generate(config: Donico.config)
  puts "GitlabCI Matrix file generated"

  # image_builder is validated by Config, so the only other case is the docker
  # backend, which legitimately has no bakefile to generate.
  case Donico.config.image_builder
  when "bake"
    Donico::Tasks::Bake.generate_bakefile
    puts "Bakefile generated"
  else
    puts "Docker backend: no Bakefile to generate"
  end
end


################
# HELP section #
################

desc "Version"
task :version do
  puts Donico.gem_version
end

# Machine readable, for CI templates that must branch on the backend. Grepping
# donico.yml for "bake" matched the string anywhere in the file (an image_name
# like "bakery", a build arg, a comment) and silently took the wrong branch.
desc "Print the configured image builder"
task :"image-builder" do
  puts Donico.config.image_builder
end

desc "Help"
task :help do
  # Built in process: shelling out to `rake -T` spawned a second Ruby that
  # reloaded donico.yml, re-evaluated its ERB and rebuilt the whole matrix, and
  # it listed the tasks of whatever Rakefile that subshell happened to find.
  described = Rake.application.tasks.select(&:comment).reject { |t| t.name == "help" }.sort_by(&:name)
  width     = described.map { |t| t.name.length }.max.to_i

  help = described.map { |t| format("  bin/rake %-#{width}s  # %s", t.name, t.comment) }.join("\n")
  puts "Usage:\n\n#{help}\n\n"
end

task default: :help
