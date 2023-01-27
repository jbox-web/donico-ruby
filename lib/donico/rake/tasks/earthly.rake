# frozen_string_literal: true

#################
# BUILD section #
#################

# Build rake commands
Donico.config.matrix.each do |m|
  version    = m.version
  distro     = m.distro
  archs      = m.archs

  namespace distro do
    namespace version do

      image = Donico::Images::Base.build_image_from_matrix(matrix: m)

      desc "Build docker image for #{distro}/#{version} #{archs}"
      task :build do
        Donico::Tasks::Earthly.build(image)
      end

      desc "Test docker image for #{distro}/#{version} #{archs}"
      task :test do
        Donico::Tasks::Earthly.test(image)
      end

      desc "Push docker image for #{distro}/#{version} #{archs}"
      task :push do
        Donico::Tasks::Earthly.push(image)
      end

      desc "Clean docker image for #{distro}/#{version} #{archs}"
      task :clean do
        Donico::Tasks::Earthly.clean(image)
      end

      desc "Login into docker image for #{distro}/#{version} #{archs}"
      task :login do
        Donico::Tasks::Earthly.login(image)
      end

    end
  end
end

###################
# RELEASE section #
###################

desc "Generate Earthfile"
task :"generate-earthfile" do
  Donico::Tasks::Earthly.generate_earthfile
  puts "Earthfile generated"
end
