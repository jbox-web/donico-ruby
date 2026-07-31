# frozen_string_literal: true

################
# LINT section #
################

desc "Lint Dockerfile"
task :"lint-dockerfile" do
  results = []
  logs    = []

  Donico.config.dockerfiles.each do |f|
    success, log = Donico.run_cmd("docker", "run", "--pull", "always", "--rm", "-v", "#{Dir.pwd}:/app", Donico.config.docker_linter, "hadolint", f)
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
  Donico.with_exit_status("docker", "run", "--pull", "always", "--rm", "-v", "#{Dir.pwd}:/app", Donico.config.commit_linter, "commitlint", "/app") do |success|
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

  case Donico.config.image_builder
  when "bake"
    Donico::Tasks::Bake.generate_bakefile
    puts "Bakefile generated"
  else
    puts "Unknown file format"
  end
end


################
# HELP section #
################

desc "Version"
task :version do
  puts Donico.gem_version
end

desc "Help"
task :help do
  help = %x(rake -T)
  help = help.split("\n").reject { |l| l.start_with?("rake help") }.map { |l| "  bin/#{l}" }.join("\n")
  puts "Usage:\n\n#{help}\n\n"
end

task default: :help
