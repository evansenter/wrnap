module Wrnap
  module Package
    class FftPopulation < FftEqBase
      THREE_COLUMN_REGEX = /^([+-]\d+\.\d+\t){2}[+-]\d+\.\d+$/

      attr_reader :starting_population, :target_population

      class PopulationProportion
        include Enumerable

        attr_reader :proportion_over_time

        def initialize(time, proportion)
          @proportion_over_time = time.zip(proportion)
        end

        def time_range(from, to)
          proportion_over_time.select { |time, _| ((from.to_f)..(to.to_f)) === time }
        end

        def time_points; proportion_over_time.map(&:first); end
        def proportion_points; proportion_over_time.map(&:last); end

        def each
          proportion_over_time.each { |_| yield _ }
        end

        def inspect
          "#<Wrnap::Package::Population::PopulationProportion time: (%f..%f), proportion: (%f..%f)>" % [
            time_points[0],
            time_points[-1],
            proportion_points[0],
            proportion_points[-1],
          ]
        end
      end

      def post_process
        unless response.empty?
          time_points, target_population, starting_population = response.split(/\n/).select { |line| line =~ THREE_COLUMN_REGEX }.map { |line| line.split(/\t/).map(&:to_f) }.transpose
          @starting_population = PopulationProportion.new(time_points, starting_population)
          @target_population   = PopulationProportion.new(time_points, target_population)
        end
      end
    end
  end
end
