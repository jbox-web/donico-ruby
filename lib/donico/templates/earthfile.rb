# frozen_string_literal: true

module Donico
  module Templates
    class Earthfile < Base

      class << self
        def generate
          file = new
          file.write
          file
        end
      end

      def initialize(template: Donico.root.join("lib/donico/data/templates/earthfile.erb"), file: "Earthfile", **)
        super data: { images: Donico.images_list }, template: template, file: file
      end

    end
  end
end
