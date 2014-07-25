module Wrnap
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

      def collapsed_helices(lonely_bp: false)
        helices.map { |((i, j), *rest)| Helix.new(i, j, rest.length + 1) }.select { |helix| lonely_bp ? helix : helix.length > 1 }
      end
    end

    class Helix
      attr_reader :i, :j
      attr_accessor :length

      def initialize(i, j, length)
        @i, @j, @length = i, j, length
      end

      def reindex!(rna)
        tap do
          if i < 0 && j < 0
            @i = rna.seq.length + i
            @j = rna.seq.length + j
          else
            @i = i - rna.seq.length
            @j = j - rna.seq.length
          end
        end
      end

      def name
        "(%d, %d)" % [i, j]
      end

      def inspect
        "#<Wrnap::Rna::Helix: %d %d %d>" % [i, j, length]
      end
    end
  end
end
