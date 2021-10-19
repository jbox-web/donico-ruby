# frozen_string_literal: true

module Donico
  class Templates

    class << self

      def generate_earthfile(config)
        new(config, Donico.root.join("lib/donico/templates/earthfile.erb")).write
      end

    end

    attr_reader :config, :template

    def initialize(config, template)
      @config = config
      @template = template
    end


    def write
      File.open("Earthfile", "w") do |f|
        f.write render_template(template)
      end
    end


    def render_template(template)
      ERB.new(File.read(template), trim_mode: "-").result_with_hash(template_data)
    end


    def template_data
      { images: images_list }
    end


    def images_list
      images = []
      config.matrix.each do |m|
        opts = m.to_h.merge(name: config.docker_image_name, registry: config.docker_registry, timestamp: config.timestamp)
        images << Donico::Images::Earthly.new(**opts)
      end
      images
    end

  end
end
