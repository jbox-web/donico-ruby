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
  version    = m["version"].to_s
  distro     = m["distro"]
  archs      = m["archs"]
  tags       = m["tags"] || []
  build_args = m["build_args"] || []
  test_args  = m["test_args"] || []

  archs.each do |arch|
    namespace arch do
      namespace distro do
        namespace version do

          opts = { name: image_name, registry: registry, arch: arch, distro: distro, version: version, timestamp: timestamp, tags: tags, build_args: build_args, test_args: test_args }
          image = Donico::Images::Docker.new(**opts)

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
