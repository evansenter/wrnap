module Wrnap
  module Package
    class FftEq < FftEqBase
      attr_reader :equilibrium

      self.default_flags = ->(context, flags) do
        {
          "--fftbor2d-i"   => context.data.seq,
          "--fftbor2d-j"   => context.data.str_1,
          "--fftbor2d-k"   => context.data.str_2,
          "--population-q" => true
        }
      end

      def post_process
        raw_eq_time  = (response.match(/index\tlogtime\n\d+\t(.*)\n/) || [])[1] || ""
        @equilibrium = (raw_eq_time =~ /^(|-?Infinity)$/ ? -1 : 10 ** raw_eq_time.to_f)
      end
    end
  end
end
