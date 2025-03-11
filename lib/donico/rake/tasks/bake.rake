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
        Donico::Tasks::Bake.build(image)
      end

      desc "Test docker image for #{distro}/#{version} #{archs}"
      task :test do
        Donico::Tasks::Bake.test(image)
      end

      desc "Push docker image for #{distro}/#{version} #{archs}"
      task :push do
        Donico::Tasks::Bake.push(image)
      end

      desc "Clean docker image for #{distro}/#{version} #{archs}"
      task :clean do
        Donico::Tasks::Bake.clean(image)
      end

      desc "Login into docker image for #{distro}/#{version} #{archs}"
      task :login do
        Donico::Tasks::Bake.login(image)
      end

    end
  end
end
