module Wrnap
  module Global
    module Runner
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def exec_exists?(name)
          !%x[which RNA#{name.to_s.downcase}].empty? || !%x[which #{name.to_s.downcase}].empty?
        end
        
        def exec_name
          executable_name.respond_to?(:call) ? executable_name[self] : executable_name
        end

        def run(*data)
          flags = data.length > 1 && data.last.is_a?(Hash) ? data.pop : {}
          new(data).run(flags)
        end
      end

      module InstanceMethods
        def run(flags = {})
          unless response
            tap do
              @runtime = Benchmark.measure do
                pre_run_check
                merged_flags     = recursively_merge_flags(flags)
                runnable_command = run_command(merged_flags)

                Wrnap.debugger { runnable_command }

                @response        = %x[#{runnable_command}]
                post_process if respond_to?(:post_process)
              end

              Wrnap.debugger { "Total runtime: %.3f sec." % runtime.real }
            end
          else
            self
          end
        end

        def pre_run_check
          valid_to_run = if self.class.instance_variable_get(:@pre_run_checked)
            self.class.instance_variable_get(:@valid_to_run)
          else
            Wrnap.debugger { "Checking existence of executable %s." % exec_name }
            self.class.module_eval do
              @pre_run_checked = true
              @valid_to_run    = !%x[which #{exec_name}].empty?
            end
          end
          
          unless valid_to_run
            raise RuntimeError.new("#{exec_name} is not defined on this machine")
          end
        end

        def exec_name
          self.class.exec_name
        end

        def recursively_merge_flags(flags)
          rmerge = ->(old_hash, new_hash) do
            inner_hash = {}

            old_hash.merge(new_hash) do |key, old_value, new_value|
              inner_hash[key] = [old_value, new_value].map(&:class).uniq == [Hash] ? rmerge[old_value, new_value] : new_value
            end
          end

          rmerge[base_flags(flags), flags].tap do |merged_flags|
            Wrnap.debugger { "%s: %s" % [self.class.name, merged_flags.inspect] }
          end
        end

        def base_flags(flags)
          default_flags.respond_to?(:call) ? default_flags[self, flags] : default_flags
        end

        def run_command(flags)
          "echo %s | %s %s" % [
            "'%s'" % call_with.map { |datum| data.send(datum) }.join(?\n),
            exec_name,
            stringify_flags(flags)
          ]
        end

        def stringify_flags(flags)
          flags.inject("") do |string, (flag, value)|
            parameter = if value == :empty || value.class == TrueClass
              " -%s" % flag
            else
              if quote_flag_params.map(&:to_s).include?(flag.to_s)
                " -%s '%s'" % [flag, value.to_s.gsub(/'/) { %|\'| }]
              else
                " -%s %s" % [flag, value]
              end
            end

            (string + parameter).strip
          end.tap do
            @flags = flags
          end
        end
      end
    end
  end
end
