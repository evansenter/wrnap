module Wrnap
  module Package
    class FftEqBase < Base
      self.executable_name = "FFTeq"

      self.default_flags = ->(context, flags) do
        {
          "-fftbor2d-i" => context.data.seq,
          "-fftbor2d-j" => context.data.str_1,
          "-fftbor2d-k" => context.data.str_2
        }
      end
      self.quote_flag_params = %w|-fftbor2d-i -fftbor2d-j -fftbor2d-k|

      def run_command(flags)
        Wrnap.debugger { "Running #{exec_name} on #{data.inspect}" }

        "%s %s" % [exec_name, stringify_flags(flags)]
      end
    end
  end
end
