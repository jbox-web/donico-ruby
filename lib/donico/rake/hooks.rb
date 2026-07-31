# frozen_string_literal: true

# Taken from: https://github.com/guillermo/rake-hooks
#
# All three hooks reach into Rake's private @tasks ivar to drop a task before
# redefining it. That coupling is deliberate but not optional: as of Rake 13.3.1
# the public API exposes only Rake::Task.clear, which wipes *every* task, so
# there is no supported way to remove a single one. A Rake upgrade that renames
# or encapsulates @tasks breaks before/after/redefine in every consuming repo at
# once, which is why spec/donico/rake/hooks_spec.rb covers all three.

module Donico
  module Rake
    module Hooks

      # rubocop:disable Performance/RedundantBlockCall
      def before(*task_names, &new_task)
        task_names.each do |task_name|
          old_task = ::Rake.application.instance_variable_get(:@tasks).delete(task_name.to_s)
          desc old_task.full_comment
          task task_name => old_task.prerequisites do
            new_task.call
            old_task.invoke
          end
        end
      end

      # CAVEAT: `after` cannot wrap a task that ends with Donico.exec (build, test,
      # clean, login, and push on the bake backend). Kernel.exec replaces the current
      # process, so control never returns here and the block is silently skipped.
      # Use `before` or `redefine` for those tasks.
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Style/RescueStandardError
      def after(*task_names, &new_task)
        options = task_names.last.is_a?(Hash) ? task_names.pop : {}
        ignore_exceptions = options.delete(:ignore_exceptions) || false

        task_names.each do |task_name|
          old_task = ::Rake.application.instance_variable_get(:@tasks).delete(task_name.to_s)
          desc old_task.full_comment
          task task_name => old_task.prerequisites do
            begin
              old_task.invoke
            rescue
              raise unless ignore_exceptions
            end

            new_task.call
          end
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Style/RescueStandardError

      def redefine(*task_names, &new_task)
        task_names.each do |task_name|
          old_task = ::Rake.application.instance_variable_get(:@tasks).delete(task_name.to_s)
          desc old_task.full_comment
          task task_name => old_task.prerequisites do
            new_task.call
          end
        end
      end
      # rubocop:enable Performance/RedundantBlockCall

    end
  end
end
