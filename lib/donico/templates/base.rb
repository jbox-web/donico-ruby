# frozen_string_literal: true

module Donico
  module Templates
    class Base

      attr_reader :template, :data, :file

      def initialize(template:, data:, file:)
        @template = template
        @data     = data
        @file     = file
      end


      def write(dest = file)
        File.write(dest, render)
      end


      def render
        ERB.new(File.read(template), trim_mode: "-").result_with_hash(data)
      end

    end
  end
end
