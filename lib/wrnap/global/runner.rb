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
        def run(user_flags = {})
          unless response
            tap do
              @runtime = Benchmark.measure do
                pre_run_check
                merged_flags     = recursively_merge_flags(user_flags)
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
        
        def exec_name
          self.class.exec_name
        end
        
        private
        
        def run_command(user_flags)
          "echo %s | %s %s" % [
            "'%s'" % call_with.map { |datum| data.send(datum).to_s }.join(?\n),
            exec_name,
            stringify_flags(user_flags)
          ]
        end
        
        def pre_run_check
          valid_to_run = if self.class.instance_variable_get(:@pre_run_checked)
            self.class.instance_variable_get(:@valid_to_run)
          else
            Wrnap.debugger { "Checking existence of executable %s." % exec_name }
            self.class.class_eval do
              @pre_run_checked = true
              @valid_to_run    = exec_exists?(exec_name)
            end
          end
          
          
          raise RuntimeError.new("#{exec_name} is not defined on this machine") unless valid_to_run
        end

        def recursively_merge_flags(user_flags)
          base_flags(user_flags).merge(user_flags).tap do |merged_flags|
            Wrnap.debugger { "%s: %s" % [self.class.name, merged_flags.inspect] }
          end
        end

        def base_flags(user_flags)
          default_flags.respond_to?(:call) ? default_flags[self, user_flags] : default_flags
        end

        def stringify_flags(flags)
          flags.inject("") do |string, (flag, value)|
            "%s %s" % [string, stringify_flag(flag, value)]
          end.tap do
            @flags = flags
          end
        end
        
        def stringify_flag(flag, value)
          flag = cast_symbol_flags(flag)
          
          if value == :empty || value == true
            flag
          elsif quote_flag_params.map(&method(:cast_symbol_flags)).include?(flag)
            "%s '%s'" % [flag, value.to_s.gsub(/'/) { %[\'] }]
          else
            "%s %s" % [flag, value.to_s]
          end
        end
        
        def cast_symbol_flags(flag)
          flag.is_a?(Symbol) ? "-%s" % flag : flag
        end
      end
    end
  end
end
