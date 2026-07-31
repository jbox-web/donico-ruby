# frozen_string_literal: true

module Donico
  module Templates
    # Escaping helpers for values interpolated into the generated docker-bake.hcl.
    module Hcl
      module_function

      # Escapes a value for insertion inside a quoted HCL string.
      #
      # Backslash first, then the double quote, otherwise the backslash inserted by
      # the quote escaping would be escaped again.
      #
      # `$` is deliberately left alone: `${...}` inside a bake value is a documented
      # HCL variable reference, used by donico configs for secret sources such as
      # "${HOME}/.aws/credentials". Escaping it would break that usage.
      def escape(value)
        value.to_s.gsub("\\", "\\\\\\\\").gsub('"', '\"')
      end
    end
  end
end
