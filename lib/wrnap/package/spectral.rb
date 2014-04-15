module Wrnap
  module Package
    class Spectral < Base
      self.default_flags = ->(context, flags) do
        {
          s: context.data.seq,
          k: context.data.str_1,
          l: context.data.str_2
        }
      end
      self.quote_flag_params = %i|s k l|

      attr_reader :eigenvalues, :time_kinetics

      def run_command(flags)
        Wrnap.debugger { "Running #{exec_name} on #{data.inspect}" }

        "%s %s" % [exec_name, stringify_flags(flags)]
      end

      def post_process
      end
    end
  end
end
