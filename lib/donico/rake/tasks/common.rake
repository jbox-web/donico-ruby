# frozen_string_literal: true

################
# LINT section #
################

desc "Lint Dockerfile"
task :"lint-dockerfile" do
  Donico.config.dockerfiles.each do |f|
    Donico.run_cmd("docker", "run", "--pull", "always", "--rm", "-v", "#{Dir.pwd}:/app", Donico.config.docker_linter, "hadolint", f) do |success|
      puts("Dockerfile is OK!") if success
    end
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

desc "Generate GitlabCI matrix and Earthfile"
task :"generate-files" do
  Donico::Matrix.generate(config: Donico.config)
  puts "GitlabCI Matrix file generated"

  case Donico.config.image_builder
  when "earthly"
    Donico::Tasks::Earthly.generate_earthfile
    puts "Earthfile generated"
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
