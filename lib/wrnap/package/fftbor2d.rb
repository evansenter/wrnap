module Wrnap
  module Package
    class Fftbor2d < EnergyGrid2d
      self.executable_name = "FFTbor2D"
      self.default_flags   = ->(_, flags) { (flags.keys & %i|m s|).empty? ? { s: :empty } : {} }

      def run_command(flags)
        Wrnap.debugger { "Running #{exec_name} on #{data.inspect}" }

        "%s %s -f %s" % [
          exec_name,
          stringify_flags(flags),
          data.temp_fa_file!
        ]
      end

      def distribution
        response.split(/\n/).map { |line| line.scanf("%d\t%d\t%f\t%f") }
      end
    end
  end
end
