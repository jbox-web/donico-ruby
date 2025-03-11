# frozen_string_literal: true

module Donico
  module Templates
    class Bakefile < Base

      class << self
        def generate
          file = new
          file.write
          file
        end
      end

      def initialize(template: Donico.root.join("lib/donico/data/templates/bakefile.erb"), file: "docker-bake.hcl", **)
        super(data: { images: Donico.images_list }, template: template, file: file)
      end

    end
  end
end
