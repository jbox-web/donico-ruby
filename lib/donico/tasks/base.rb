# frozen_string_literal: true

module Donico
  module Tasks
    class Base
      class << self
        def build(image)
          new(image).build
        end

        def test(image)
          new(image).test
        end

        def tag(image)
          new(image).tag
        end

        def push(image)
          new(image).push
        end

        def clean(image)
          new(image).clean
        end

        def login(image)
          new(image).login
        end

        def syscall(*cmd)
          begin
            stdout, stderr, status = Open3.capture3(*cmd)
            out = status.success? ? stdout : stderr
            puts out
          rescue StandardError => e
            puts e
          end
        end
      end

      attr_reader :image

      def initialize(image)
        @image = image
      end
    end
  end
end
