module Wrnap
  class Rna
    module Motifs
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
      attr_reader :i, :j, :length

      def initialize(i, j, length)
        @i, @j, @length = i, j, length
      end
      
      def k; i + length - 1; end
      def l; j - length + 1; end
      
      def to_loops
        [Loop.new(i, k), Loop.new(l, j)]
      end

      def reindex!(rna)
        tap do
          if i < 0 && j < 0
            @i = rna.len + i
            @j = rna.len + j
          else
            @i = i - rna.len
            @j = j - rna.len
          end
        end
      end

      def name
        "(%d..%d, %d..%d)" % [i, k, l, j]
      end

      def inspect
        "#<Helix: %s>" % name
      end
    end
    
    class Loop
      attr_reader :i, :j
      
      def initialize(i, j)
        @i, @j = i, j
      end
      
      def name
        "(%d, %d)" % [i, j]
      end
      
      def inspect
        "#<Loop: %s>" % name
      end
    end
  end
end
