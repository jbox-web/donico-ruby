# frozen_string_literal: true

#################
# BUILD section #
#################

# Fetch config
image_name = Donico.config.docker_image_name
registry   = Donico.config.docker_registry
matrix     = Donico.config.matrix
timestamp  = Donico.config.timestamp

# Build rake commands
matrix.each do |m|
  version    = m.version
  distro     = m.distro
  archs      = m.archs

  namespace distro do
    namespace version do

      opts  = m.to_h.merge(name: image_name, registry: registry, timestamp: timestamp)
      image = Donico::Images::Earthly.new(**opts)

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
  Donico::Templates.generate_earthfile(Donico.config)
end
