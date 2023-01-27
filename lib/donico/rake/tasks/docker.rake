# frozen_string_literal: true

#################
# BUILD section #
#################

# Build rake commands
Donico.config.matrix.each do |m|
  version    = m.version
  distro     = m.distro
  archs      = m.archs

  archs.each do |arch|
    namespace arch.split("/").last do
      namespace distro do
        namespace version do

          image = Donico::Images::Base.build_image_from_matrix(matrix: m, arch: arch)

          desc "Build docker image for #{arch}/#{distro}/#{version}"
          task :build do
            Donico::Tasks::Docker.build(image)
          end

          desc "Test docker image for #{arch}/#{distro}/#{version}"
          task :test do
            Donico::Tasks::Docker.test(image)
          end

          desc "Tag docker image for #{arch}/#{distro}/#{version}"
          task :tag do
            Donico::Tasks::Docker.tag(image)
          end

          desc "Push docker image for #{arch}/#{distro}/#{version}"
          task :push do
            Donico::Tasks::Docker.push(image)
          end

          desc "Clean docker image for #{arch}/#{distro}/#{version}"
          task :clean do
            Donico::Tasks::Docker.clean(image)
          end

          desc "Login into docker image for #{arch}/#{distro}/#{version}"
          task :login do
            Donico::Tasks::Docker.login(image)
          end

        end
      end
    end
  end
end
