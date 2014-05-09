module Wrnap
  module Package
    class FftEq < FftEqBase
      attr_reader :equilibrium

      self.default_flags = ->(context, flags) do
        {
          "-fftbor2d-i"   => context.data.seq,
          "-fftbor2d-j"   => context.data.str_1,
          "-fftbor2d-k"   => context.data.str_2,
          "-population-e" => 1e-4
        }
      end

      def post_process
        @equilibrium = (response.empty? || response =~ /Infinity/ ? -1 : 10 ** response.strip.to_f)
      end
    end
  end
end
