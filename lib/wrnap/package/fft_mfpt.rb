# Maybe add something like flagsets so that common option groups can be combined together.
# Also, add a rerun feature.

module Wrnap
  module Package
    class FftMfpt < Base
      self.executable_name = "FFTmfpt"

      self.default_flags = ->(context, flags) do
        {
          "--fftbor2d-i" => context.data.seq,
          "--fftbor2d-j" => context.data.str_1,
          "--fftbor2d-k" => context.data.str_2,
          "X"           => true
        }
      end
      self.quote_flag_params = %w|--fftbor2d-i --fftbor2d-j --fftbor2d-k|

      attr_reader :mfpt

      def run_command(flags)
        Wrnap.debugger { "Running #{exec_name} on #{data.inspect}" }

        "%s %s" % [exec_name, stringify_flags(flags)]
      end

      def post_process
        @mfpt = response.to_f
      end
    end
  end
end
