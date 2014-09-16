module Wrnap
  class Rna    
    class Helix
      attr_reader :i, :j, :length

      def initialize(i, j, length)
        @i, @j, @length = i, j, length
      end
      
      def k; i + length - 1; end
      def l; j - length + 1; end
      
      def in(sequence)
        (0...length).map do |stem_position|
          [sequence[i + stem_position], sequence[j - stem_position]]
        end
      end
      
      def to_loops
        [Loop.new(i, k), Loop.new(l, j)]
      end
      
      def apply!(structure)
        structure.tap do
          structure[i, length] = ?( * length
          structure[l, length] = ?) * length
        end
      end
      
      def merge!(helix)
        @length = helix.k - i + 1
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
        "(%d..%d, %d..%d [%d])" % [i, k, l, j, length]
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
      
      def in(sequence)
        sequence[i..j]
      end
      
      def length
        j - i + 1
      end
      
      def name
        "(%d, %d [%d])" % [i, j, length]
      end
      
      def inspect
        "#<Loop: %s>" % name
      end
    end
  end
end
