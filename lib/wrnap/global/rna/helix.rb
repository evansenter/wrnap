module Wrnap
  module Global
    class Rna
      module HelixFunctions
        def helices
          array = base_pairs.sort_by(&:first).map(&:to_a)

          unless array.empty?
            array[1..-1].inject([[array.first]]) do |bins, (i, j)|
              bins.tap { bins[-1][-1] == [i - 1, j + 1] ? bins[-1] << [i, j] : bins << [[i, j]] }
            end
          else
            []
          end
        end

        def collapsed_helices
          helices.map { |((i, j), *rest)| Helix.new(i, j, rest.length + 1) }
        end
      end

      class Helix
        attr_reader :i, :j
        attr_accessor :length

        def initialize(i, j, length)
          @i, @j, @length = i, j, length
        end

        def name
          "(%d, %d)" % [i, j]
        end
      end
    end
  end
end
